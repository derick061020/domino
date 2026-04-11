import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import '../languages/app_localizations.dart';

class DominoDetectionResult {
  final List<int> detectedPoints;
  final String imagePath;
  final String analysisInfo;
  final String? annotatedImagePath;

  DominoDetectionResult({
    required this.detectedPoints,
    required this.imagePath,
    required this.analysisInfo,
    this.annotatedImagePath,
  });
}

class DominoVisionService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<String?> captureImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      return image?.path;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }

  Future<DominoDetectionResult> detectDominoPoints(String imagePath,
      {AppLocalizations? loc}) async {
    try {
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? original = img.decodeImage(imageBytes);

      if (original == null) {
        throw Exception('No se pudo cargar la imagen');
      }

      // Redimensionar para procesamiento más rápido y consistente
      img.Image image = original;
      if (image.width > 800) {
        image = img.copyResize(image, width: 800);
      }

      // 1. Convertir a luminancia (array 1D)
      final width = image.width;
      final height = image.height;
      final Uint8List lum = Uint8List(width * height);
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final p = image.getPixel(x, y);
          lum[y * width + x] =
              (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round().clamp(0, 255);
        }
      }

      // 2. Blur 3x3 para reducir ruido
      final Uint8List blurred = _boxBlur(lum, width, height);

      // 3. Detectar la ficha de dominó (bounding box)
      final _Rect? tileRect = _findDominoTile(blurred, width, height);

      // 4. Detectar puntos SOLO dentro de la ficha (o en toda la imagen si no se encontró)
      final _Rect roi = tileRect ??
          _Rect(
            x0: 0,
            y0: 0,
            x1: width - 1,
            y1: height - 1,
          );

      final darkDots = _detectBlobs(blurred, width, height,
          darkOnLight: true, roi: roi);
      final lightDots = _detectBlobs(blurred, width, height,
          darkOnLight: false, roi: roi);

      // Elegir el set que tenga más blobs consistentes (tamaño uniforme)
      final List<_Blob> chosen =
          _scoreBlobSet(darkDots) >= _scoreBlobSet(lightDots) ? darkDots : lightDots;

      // 5. Dibujar la ficha detectada y los círculos sobre la imagen
      String? annotatedPath;
      final annotated = img.Image.from(image);
      if (tileRect != null) {
        // Rectángulo azul alrededor de la ficha
        final blue = img.ColorRgb8(0, 150, 255);
        for (int t = 0; t < 3; t++) {
          img.drawRect(
            annotated,
            x1: tileRect.x0 - t,
            y1: tileRect.y0 - t,
            x2: tileRect.x1 + t,
            y2: tileRect.y1 + t,
            color: blue,
          );
        }
      }
      if (chosen.isNotEmpty) {
        final green = img.ColorRgb8(0, 255, 0);
        for (final blob in chosen) {
          final radius = (sqrt(blob.area / pi)).round().clamp(4, 40);
          final cx = blob.centerX.round();
          final cy = blob.centerY.round();
          for (int t = 0; t < 3; t++) {
            img.drawCircle(
              annotated,
              x: cx,
              y: cy,
              radius: radius + 2 + t,
              color: green,
            );
          }
        }
      }
      if (tileRect != null || chosen.isNotEmpty) {
        final tempDir = imageFile.parent.path;
        final ts = DateTime.now().millisecondsSinceEpoch;
        annotatedPath = '$tempDir/annotated_$ts.jpg';
        await File(annotatedPath).writeAsBytes(img.encodeJpg(annotated, quality: 85));
      }

      final totalPoints = chosen.length;

      final String info;
      if (totalPoints > 0) {
        info = loc != null
            ? loc.get('detected_n_points').replaceAll('%d', '$totalPoints')
            : 'Detected $totalPoints points in the image';
      } else {
        info = loc != null
            ? loc.get('no_points_hint')
            : 'No points detected.';
      }

      return DominoDetectionResult(
        detectedPoints: totalPoints > 0 ? [totalPoints] : [],
        imagePath: imagePath,
        annotatedImagePath: annotatedPath,
        analysisInfo: info,
      );
    } catch (e) {
      debugPrint('Error detecting domino points: $e');
      final errorLabel = loc != null ? loc.get('analysis_error') : 'Analysis error';
      return DominoDetectionResult(
        detectedPoints: [],
        imagePath: imagePath,
        analysisInfo: '$errorLabel: ${e.toString()}',
      );
    }
  }

  /// Box blur 3x3
  Uint8List _boxBlur(Uint8List lum, int width, int height) {
    final Uint8List out = Uint8List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int sum = 0;
        int count = 0;
        for (int dy = -1; dy <= 1; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= height) continue;
          for (int dx = -1; dx <= 1; dx++) {
            final nx = x + dx;
            if (nx < 0 || nx >= width) continue;
            sum += lum[ny * width + nx];
            count++;
          }
        }
        out[y * width + x] = (sum ~/ count);
      }
    }
    return out;
  }

  /// Detecta blobs con umbral adaptativo. `darkOnLight` = true detecta
  /// puntos oscuros sobre fondo claro; false al revés.
  /// Solo analiza píxeles dentro de `roi`.
  List<_Blob> _detectBlobs(Uint8List lum, int width, int height,
      {required bool darkOnLight, required _Rect roi}) {
    // Umbral adaptativo usando suma sobre ventana pequeña
    final int windowRadius = 15; // ventana ~31px
    final List<bool> isFg = List.filled(width * height, false);

    // Precomputar suma integral para media local rápida
    final List<int> integral = List.filled((width + 1) * (height + 1), 0);
    for (int y = 0; y < height; y++) {
      int rowSum = 0;
      for (int x = 0; x < width; x++) {
        rowSum += lum[y * width + x];
        integral[(y + 1) * (width + 1) + (x + 1)] =
            integral[y * (width + 1) + (x + 1)] + rowSum;
      }
    }

    const int threshDelta = 15; // cuánto debe desviarse del fondo local

    for (int y = roi.y0; y <= roi.y1; y++) {
      for (int x = roi.x0; x <= roi.x1; x++) {
        final x0 = max(roi.x0, x - windowRadius);
        final y0 = max(roi.y0, y - windowRadius);
        final x1 = min(roi.x1, x + windowRadius);
        final y1 = min(roi.y1, y + windowRadius);

        final int sum = integral[(y1 + 1) * (width + 1) + (x1 + 1)]
            - integral[y0 * (width + 1) + (x1 + 1)]
            - integral[(y1 + 1) * (width + 1) + x0]
            + integral[y0 * (width + 1) + x0];
        final int area = (x1 - x0 + 1) * (y1 - y0 + 1);
        final double mean = sum / area;
        final int pixel = lum[y * width + x];

        if (darkOnLight) {
          isFg[y * width + x] = pixel < mean - threshDelta;
        } else {
          isFg[y * width + x] = pixel > mean + threshDelta;
        }
      }
    }

    // Flood-fill para encontrar blobs (solo dentro del ROI)
    final List<int> labels = List.filled(width * height, -1);
    final List<_Blob> blobs = [];
    int labelId = 0;

    final int yMin = max(1, roi.y0);
    final int yMax = min(height - 2, roi.y1);
    final int xMin = max(1, roi.x0);
    final int xMax = min(width - 2, roi.x1);

    for (int y = yMin; y <= yMax; y++) {
      for (int x = xMin; x <= xMax; x++) {
        final idx = y * width + x;
        if (isFg[idx] && labels[idx] == -1) {
          final blob = _floodFill(isFg, labels, width, height, x, y, labelId);
          if (blob != null) blobs.add(blob);
          labelId++;
        }
      }
    }

    // Filtrar por tamaño y forma (relativo al área del ROI, no de la imagen)
    final double roiArea = roi.width.toDouble() * roi.height.toDouble();
    final double minBlobArea = roiArea * 0.001;
    final double maxBlobArea = roiArea * 0.08;

    final List<_Blob> candidates = [];
    for (final blob in blobs) {
      if (blob.area < minBlobArea || blob.area > maxBlobArea) continue;

      // Circularidad: ratio del área vs. área del círculo que cabe en el bbox
      final double bboxArea = blob.bboxWidth * blob.bboxHeight.toDouble();
      if (bboxArea == 0) continue;

      final double fillRatio = blob.area / bboxArea;
      // Un círculo en un cuadrado tiene fillRatio ~ π/4 ≈ 0.785
      // Aceptamos entre 0.55 y 1.0
      if (fillRatio < 0.55) continue;

      // Aspect ratio ~ 1 (cuadrado)
      final double aspectRatio = blob.bboxWidth / blob.bboxHeight;
      if (aspectRatio < 0.6 || aspectRatio > 1.7) continue;

      candidates.add(blob);
    }

    if (candidates.isEmpty) return [];

    // Filtrar por consistencia de tamaño: los puntos de un dominó son uniformes
    // Calcular la mediana del diámetro
    final diameters = candidates
        .map((b) => sqrt(b.area))
        .toList()
      ..sort();
    final double medianDiam = diameters[diameters.length ~/ 2];

    final List<_Blob> consistent = candidates.where((b) {
      final d = sqrt(b.area);
      return d > medianDiam * 0.55 && d < medianDiam * 1.75;
    }).toList();

    return _filterNearbyBlobs(consistent);
  }

  /// Puntúa un conjunto de blobs por su calidad:
  /// más blobs consistentes = mejor
  double _scoreBlobSet(List<_Blob> blobs) {
    if (blobs.isEmpty) return 0;
    if (blobs.length == 1) return 1;

    // Calcular desviación estándar del diámetro (cuanto menor, mejor)
    final diameters = blobs.map((b) => sqrt(b.area)).toList();
    final double mean = diameters.reduce((a, b) => a + b) / diameters.length;
    final double variance = diameters
            .map((d) => (d - mean) * (d - mean))
            .reduce((a, b) => a + b) /
        diameters.length;
    final double stdDev = sqrt(variance);
    final double cv = stdDev / mean; // coeficiente de variación

    // Score: muchos blobs con baja variación puntúa alto
    return blobs.length.toDouble() / (1.0 + cv * 2);
  }

  _Blob? _floodFill(List<bool> isFg, List<int> labels, int width, int height,
      int startX, int startY, int labelId) {
    final queue = <int>[];
    final startIdx = startY * width + startX;
    queue.add(startIdx);
    labels[startIdx] = labelId;

    int area = 0;
    int sumX = 0, sumY = 0;
    int minX = startX, maxX = startX;
    int minY = startY, maxY = startY;

    const int maxFloodSize = 8000;

    int head = 0;
    while (head < queue.length) {
      if (area > maxFloodSize) return null;

      final idx = queue[head++];
      final x = idx % width;
      final y = idx ~/ width;

      area++;
      sumX += x;
      sumY += y;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;

      // 4 vecinos
      if (x > 0) {
        final n = idx - 1;
        if (isFg[n] && labels[n] == -1) {
          labels[n] = labelId;
          queue.add(n);
        }
      }
      if (x < width - 1) {
        final n = idx + 1;
        if (isFg[n] && labels[n] == -1) {
          labels[n] = labelId;
          queue.add(n);
        }
      }
      if (y > 0) {
        final n = idx - width;
        if (isFg[n] && labels[n] == -1) {
          labels[n] = labelId;
          queue.add(n);
        }
      }
      if (y < height - 1) {
        final n = idx + width;
        if (isFg[n] && labels[n] == -1) {
          labels[n] = labelId;
          queue.add(n);
        }
      }
    }

    if (area < 8) return null;

    return _Blob(
      centerX: sumX / area,
      centerY: sumY / area,
      area: area.toDouble(),
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  List<_Blob> _filterNearbyBlobs(List<_Blob> blobs) {
    final List<_Blob> filtered = [];

    for (final blob in blobs) {
      bool tooClose = false;
      for (final existing in filtered) {
        final dx = blob.centerX - existing.centerX;
        final dy = blob.centerY - existing.centerY;
        final distance = sqrt(dx * dx + dy * dy);
        final minDist = (sqrt(blob.area) + sqrt(existing.area)) * 0.35;
        if (distance < minDist) {
          tooClose = true;
          break;
        }
      }
      if (!tooClose) {
        filtered.add(blob);
      }
    }

    return filtered;
  }

  Future<DominoDetectionResult?> showImageAnalysisDialog(
      BuildContext context, DominoDetectionResult result) async {
    final loc = AppLocalizations.of(context);
    return showDialog<DominoDetectionResult>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D44),
          title: Text(
            loc.get('analyze_points'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mostrar la imagen con los puntos detectados marcados
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220, maxWidth: 220),
                    child: Image.file(
                      File(result.annotatedImagePath ?? result.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Información general
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
                ),
                child: Text(
                  result.analysisInfo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Puntos detectados
              if (result.detectedPoints.isEmpty)
                Text(
                  loc.get('no_points_detected'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.get('detected_points'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...result.detectedPoints.map((points) => Text(
                      '· $points ${loc.get('points')}',
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    )),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                loc.get('cancel'),
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            if (result.detectedPoints.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(result);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                ),
                child: Text(
                  loc.get('use_these_points'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Blob {
  final double centerX;
  final double centerY;
  final double area;
  final int minX, maxX, minY, maxY;

  _Blob({
    required this.centerX,
    required this.centerY,
    required this.area,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  int get bboxWidth => maxX - minX + 1;
  int get bboxHeight => maxY - minY + 1;
}

class _Rect {
  final int x0, y0, x1, y1;
  _Rect({
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
  });
  int get width => x1 - x0 + 1;
  int get height => y1 - y0 + 1;
}

extension _DominoTileDetection on DominoVisionService {
  /// Encuentra el bounding box de la ficha de dominó en la imagen.
  /// Estrategia: umbralizar por media global, probar ambas polaridades
  /// (ficha clara / ficha oscura) y quedarse con el blob más grande y
  /// rectangular que tenga un área razonable.
  _Rect? _findDominoTile(Uint8List lum, int width, int height) {
    // Media global de luminancia
    int sum = 0;
    for (int i = 0; i < lum.length; i++) {
      sum += lum[i];
    }
    final double globalMean = sum / lum.length;

    _Rect? bestRect;
    double bestScore = 0;

    for (final bool brightTile in [true, false]) {
      final List<bool> isFg = List.filled(width * height, false);
      const int delta = 10;

      for (int i = 0; i < lum.length; i++) {
        if (brightTile) {
          isFg[i] = lum[i] > globalMean + delta;
        } else {
          isFg[i] = lum[i] < globalMean - delta;
        }
      }

      // Flood-fill global para encontrar el blob más grande
      final List<int> labels = List.filled(width * height, -1);
      int labelId = 0;
      _Blob? largest;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final idx = y * width + x;
          if (isFg[idx] && labels[idx] == -1) {
            final blob = _tileFloodFill(isFg, labels, width, height, x, y, labelId);
            labelId++;
            if (blob != null) {
              if (largest == null || blob.area > largest.area) {
                largest = blob;
              }
            }
          }
        }
      }

      if (largest == null) continue;

      final double imageArea = width.toDouble() * height.toDouble();
      if (largest.area < imageArea * 0.05) continue;
      if (largest.area > imageArea * 0.95) continue;

      final int bw = largest.bboxWidth;
      final int bh = largest.bboxHeight;
      if (bw < 20 || bh < 20) continue;

      final double aspectRatio = bw / bh;
      if (aspectRatio < 0.3 || aspectRatio > 3.5) continue;

      final double bboxArea = bw * bh.toDouble();
      final double fillRatio = largest.area / bboxArea;
      if (fillRatio < 0.65) continue;

      // Score: área * fillRatio (preferimos rectangulos llenos y grandes)
      final double score = largest.area * fillRatio;
      if (score > bestScore) {
        bestScore = score;
        // Añadir un pequeño margen hacia adentro para evitar tocar el borde
        final int pad = 2;
        bestRect = _Rect(
          x0: max(0, largest.minX + pad),
          y0: max(0, largest.minY + pad),
          x1: min(width - 1, largest.maxX - pad),
          y1: min(height - 1, largest.maxY - pad),
        );
      }
    }

    return bestRect;
  }

  /// Flood-fill sin límite de tamaño (usado para detectar la ficha entera).
  _Blob? _tileFloodFill(List<bool> isFg, List<int> labels, int width,
      int height, int startX, int startY, int labelId) {
    final queue = <int>[];
    final startIdx = startY * width + startX;
    queue.add(startIdx);
    labels[startIdx] = labelId;

    int area = 0;
    int sumX = 0, sumY = 0;
    int minX = startX, maxX = startX;
    int minY = startY, maxY = startY;

    int head = 0;
    while (head < queue.length) {
      final idx = queue[head++];
      final x = idx % width;
      final y = idx ~/ width;

      area++;
      sumX += x;
      sumY += y;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;

      if (x > 0) {
        final n = idx - 1;
        if (isFg[n] && labels[n] == -1) {
          labels[n] = labelId;
          queue.add(n);
        }
      }
      if (x < width - 1) {
        final n = idx + 1;
        if (isFg[n] && labels[n] == -1) {
          labels[n] = labelId;
          queue.add(n);
        }
      }
      if (y > 0) {
        final n = idx - width;
        if (isFg[n] && labels[n] == -1) {
          labels[n] = labelId;
          queue.add(n);
        }
      }
      if (y < height - 1) {
        final n = idx + width;
        if (isFg[n] && labels[n] == -1) {
          labels[n] = labelId;
          queue.add(n);
        }
      }
    }

    if (area < 400) return null;

    return _Blob(
      centerX: sumX / area,
      centerY: sumY / area,
      area: area.toDouble(),
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }
}
