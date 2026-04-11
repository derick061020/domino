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

      // 4. Detectar puntos con múltiples métodos mejorados
      final _Rect roi = tileRect ??
          _Rect(
            x0: 0,
            y0: 0,
            x1: width - 1,
            y1: height - 1,
          );

      // Múltiples métodos de detección para encontrar más puntos
      final List<List<_Blob>> allCandidates = [];
      
      // Método 1: Detección adaptativa existente
      allCandidates.add(_detectBlobs(blurred, width, height,
          darkOnLight: true, roi: roi));
      allCandidates.add(_detectBlobs(blurred, width, height,
          darkOnLight: false, roi: roi));
      
      // Método 2: Detección por umbral global
      allCandidates.add(_detectBlobsGlobalThreshold(lum, width, height, roi: roi));
      
      // Método 3: Detección por umbral Otsu
      allCandidates.add(_detectBlobsOtsu(lum, width, height, roi: roi));

      // Elegir el mejor conjunto de blobs
      List<_Blob> chosen = [];
      double bestScore = 0;
      
      for (final candidate in allCandidates) {
        final score = _scoreBlobSet(candidate);
        if (score > bestScore) {
          bestScore = score;
          chosen = candidate;
        }
      }

      // 5. Dibujar la ficha detectada y los puntos con mejor visualización
      String? annotatedPath;
      final annotated = img.Image.from(image);
      
      if (tileRect != null) {
        // Dibujar ficha de domino detectada con mejor visualización
        _drawDominoTile(annotated, tileRect, width, height);
      }
      
      if (chosen.isNotEmpty) {
        // Dibujar puntos detectados con mejor visualización
        _drawDetectedPoints(annotated, chosen, width, height);
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
        final String tileInfo = tileRect != null 
            ? 'Ficha detectada (${tileRect.width}x${tileRect.height})'
            : 'Sin ficha detectada';
        info = loc != null
            ? '${loc.get('detected_n_points').replaceAll('%d', '$totalPoints')} - $tileInfo'
            : 'Detected $totalPoints points - $tileInfo';
      } else {
        final String tileInfo = tileRect != null 
            ? 'Ficha detectada pero sin puntos'
            : 'No se detectó ficha ni puntos';
        info = loc != null
            ? '${loc.get('no_points_hint')} - $tileInfo'
            : 'No points detected - $tileInfo';
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

  /// Flood-fill para encontrar blobs (con límite de tamaño para evitar overflow)
  _Blob? _floodFill(List<bool> isFg, List<int> labels, int width, int height,
      int startX, int startY, int labelId) {
    final queue = <int>[];
    final startIdx = startY * width + startX;
    if (!isFg[startIdx]) return null;

    labels[startIdx] = labelId;
    queue.add(startIdx);

    int sumX = 0, sumY = 0, area = 0;
    int minX = startX, maxX = startX, minY = startY, maxY = startY;

    int processedCount = 0;
    const int maxPixels = 50000; // Límite para evitar overflow

    while (queue.isNotEmpty && processedCount < maxPixels) {
      final idx = queue.removeLast();
      final x = idx % width;
      final y = idx ~/ width;

      sumX += x;
      sumY += y;
      area++;
      minX = min(minX, x);
      maxX = max(maxX, x);
      minY = min(minY, y);
      maxY = max(maxY, y);

      // 8-vecinos
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          final nx = x + dx;
          final ny = y + dy;
          if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
            final nIdx = ny * width + nx;
            if (isFg[nIdx] && labels[nIdx] == -1) {
              labels[nIdx] = labelId;
              queue.add(nIdx);
            }
          }
        }
      }
      processedCount++;
    }

    if (area < 300) return null;

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

  /// Extraer blobs de una imagen binaria
  List<_Blob> _extractBlobsFromBinary(List<bool> isFg, int width, int height, {required _Rect roi}) {
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

    // Filtrar por tamaño y forma (más permisivo para encontrar más puntos)
    final double roiArea = roi.width.toDouble() * roi.height.toDouble();
    final double minBlobArea = roiArea * 0.0005; // Más pequeño para detectar más puntos
    final double maxBlobArea = roiArea * 0.15;   // Más grande

    final List<_Blob> candidates = [];
    for (final blob in blobs) {
      if (blob.area < minBlobArea || blob.area > maxBlobArea) continue;

      // Circularidad más permisiva
      final double bboxArea = blob.bboxWidth * blob.bboxHeight.toDouble();
      if (bboxArea == 0) continue;

      final double fillRatio = blob.area / bboxArea;
      if (fillRatio < 0.3) continue; // Más permisivo

      // Aspect ratio más permisivo
      final double aspectRatio = blob.bboxWidth / blob.bboxHeight;
      if (aspectRatio < 0.25 || aspectRatio > 4.0) continue; // Más permisivo

      candidates.add(blob);
    }

    if (candidates.isEmpty) return [];

    // Filtrar por consistencia de tamaño (más permisivo)
    final diameters = candidates
        .map((b) => sqrt(b.area))
        .toList()
      ..sort();
    final double medianDiam = diameters[diameters.length ~/ 2];

    final List<_Blob> consistent = candidates.where((b) {
      final d = sqrt(b.area);
      return d > medianDiam * 0.25 && d < medianDiam * 3.0; // Más permisivo
    }).toList();

    return _filterNearbyBlobs(consistent);
  }

  /// Detección de blobs usando umbral global
  List<_Blob> _detectBlobsGlobalThreshold(Uint8List lum, int width, int height, {required _Rect roi}) {
    // Calcular umbral global
    int sum = 0;
    int count = 0;
    for (int y = roi.y0; y <= roi.y1; y++) {
      for (int x = roi.x0; x <= roi.x1; x++) {
        sum += lum[y * width + x];
        count++;
      }
    }
    final double mean = sum / count;
    final int threshold = mean.round();

    // Aplicar umbral
    final List<bool> isFg = List.filled(width * height, false);
    for (int y = roi.y0; y <= roi.y1; y++) {
      for (int x = roi.x0; x <= roi.x1; x++) {
        final pixel = lum[y * width + x];
        isFg[y * width + x] = pixel < threshold - 15 || pixel > threshold + 15;
      }
    }

    return _extractBlobsFromBinary(isFg, width, height, roi: roi);
  }

  /// Detección de blobs usando umbral Otsu
  List<_Blob> _detectBlobsOtsu(Uint8List lum, int width, int height, {required _Rect roi}) {
    // Calcular histograma
    final List<int> histogram = List.filled(256, 0);
    int pixelCount = 0;
    
    for (int y = roi.y0; y <= roi.y1; y++) {
      for (int x = roi.x0; x <= roi.x1; x++) {
        final pixel = lum[y * width + x];
        histogram[pixel]++;
        pixelCount++;
      }
    }
    
    // Calcular umbral Otsu
    double bestThreshold = 0;
    double bestVariance = 0;
    
    for (int t = 0; t < 256; t++) {
      double w0 = 0, w1 = 0, mu0 = 0, mu1 = 0;
      
      for (int i = 0; i < 256; i++) {
        if (i <= t) {
          w0 += histogram[i];
          mu0 += i * histogram[i];
        } else {
          w1 += histogram[i];
          mu1 += i * histogram[i];
        }
      }
      
      if (w0 > 0 && w1 > 0) {
        mu0 /= w0;
        mu1 /= w1;
        w0 /= pixelCount;
        w1 /= pixelCount;
        
        final double betweenClassVariance = w0 * w1 * (mu0 - mu1) * (mu0 - mu1);
        if (betweenClassVariance > bestVariance) {
          bestVariance = betweenClassVariance;
          bestThreshold = t.toDouble();
        }
      }
    }
    
    // Aplicar umbral
    final List<bool> isFg = List.filled(width * height, false);
    for (int y = roi.y0; y <= roi.y1; y++) {
      for (int x = roi.x0; x <= roi.x1; x++) {
        final pixel = lum[y * width + x];
        isFg[y * width + x] = pixel < bestThreshold;
      }
    }
    
    return _extractBlobsFromBinary(isFg, width, height, roi: roi);
  }

  /// Dibujar ficha de domino detectada
  void _drawDominoTile(img.Image annotated, _Rect tileRect, int width, int height) {
    // Colores para la ficha
    final blue = img.ColorRgb8(0, 150, 255);
    final lightBlue = img.ColorRgb8(100, 180, 255);
    final darkBlue = img.ColorRgb8(0, 100, 200);
    
    // Relleno semitransparente de la ficha
    for (int y = tileRect.y0; y <= tileRect.y1; y++) {
      for (int x = tileRect.x0; x <= tileRect.x1; x++) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          final pixel = annotated.getPixel(x, y);
          annotated.setPixel(x, y, img.ColorRgb8(
            (pixel.r * 0.6 + lightBlue.r * 0.4).round(),
            (pixel.g * 0.6 + lightBlue.g * 0.4).round(),
            (pixel.b * 0.6 + lightBlue.b * 0.4).round(),
          ));
        }
      }
    }
    
    // Borde grueso alrededor de la ficha
    for (int t = 0; t < 5; t++) {
      final color = t < 2 ? darkBlue : (t < 4 ? blue : lightBlue);
      for (int y = tileRect.y0 - t; y <= tileRect.y1 + t; y++) {
        for (int x = tileRect.x0 - t; x <= tileRect.x1 + t; x++) {
          if (x >= 0 && x < width && y >= 0 && y < height) {
            if (y == tileRect.y0 - t || y == tileRect.y1 + t || 
                x == tileRect.x0 - t || x == tileRect.x1 + t) {
              annotated.setPixel(x, y, color);
            }
          }
        }
      }
    }
    
    // Etiqueta "FICHA" arriba de la ficha
    if (tileRect.y0 > 25) {
      final String label = "FICHA";
      final int labelX = tileRect.x0 + (tileRect.width - label.length * 10) ~/ 2;
      final int labelY = tileRect.y0 - 10;
      
      // Dibujar texto simple
      for (int i = 0; i < label.length; i++) {
        for (int dy = 0; dy < 12; dy++) {
          for (int dx = 0; dx < 8; dx++) {
            final int px = labelX + i * 10 + dx;
            final int py = labelY + dy;
            if (px >= 0 && px < width && py >= 0 && py < height) {
              // Letra simple: F, I, C, H, A
              if (_isPixelInLetter(label[i], dx, dy)) {
                annotated.setPixel(px, py, darkBlue);
              }
            }
          }
        }
      }
    }
  }

  /// Verificar si un píxel está dentro de una letra
  bool _isPixelInLetter(String letter, int x, int y) {
    switch (letter) {
      case 'F':
        return (x == 0 || x == 6) || (y == 0 || y == 6);
      case 'I':
        return x == 3 || (y == 0 || y == 6);
      case 'C':
        return (x == 0 || x == 6) || (y == 0 || y == 6);
      case 'H':
        return (x == 0 || x == 6) || (y >= 2 && y <= 4);
      case 'A':
        return (x == 0 || x == 6) || (y == 0 || y == 3) || (y >= 2 && y <= 4 && x >= 2 && x <= 4);
      default:
        return false;
    }
  }

  /// Dibujar puntos detectados
  void _drawDetectedPoints(img.Image annotated, List<_Blob> points, int width, int height) {
    final green = img.ColorRgb8(0, 255, 0);
    final brightGreen = img.ColorRgb8(150, 255, 150);
    final darkGreen = img.ColorRgb8(0, 200, 0);
    
    for (int i = 0; i < points.length; i++) {
      final blob = points[i];
      final radius = (sqrt(blob.area / pi)).round().clamp(5, 25);
      final cx = blob.centerX.round();
      final cy = blob.centerY.round();
      
      // Círculo relleno semitransparente
      for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
          if (dx * dx + dy * dy <= radius * radius) {
            final int px = cx + dx;
            final int py = cy + dy;
            if (px >= 0 && px < width && py >= 0 && py < height) {
              final pixel = annotated.getPixel(px, py);
              annotated.setPixel(px, py, img.ColorRgb8(
                (pixel.r * 0.3 + brightGreen.r * 0.7).round(),
                (pixel.g * 0.3 + brightGreen.g * 0.7).round(),
                (pixel.b * 0.3 + brightGreen.b * 0.7).round(),
              ));
            }
          }
        }
      }
      
      // Borde del círculo
      for (int t = 0; t < 3; t++) {
        img.drawCircle(
          annotated,
          x: cx,
          y: cy,
          radius: radius + 2 + t,
          color: t == 0 ? darkGreen : green,
        );
      }
      
      // Número del punto
      final String numStr = (i + 1).toString();
      final int numX = cx - (numStr.length * 4) ~/ 2;
      final int numY = cy - 4;
      
      for (int j = 0; j < numStr.length; j++) {
        for (int dy = 0; dy < 8; dy++) {
          for (int dx = 0; dx < 6; dx++) {
            final int px = numX + j * 8 + dx;
            final int py = numY + dy;
            if (px >= 0 && px < width && py >= 0 && py < height) {
              // Dibujar número simple
              if (_isPixelInNumber(numStr[j], dx, dy)) {
                annotated.setPixel(px, py, img.ColorRgb8(255, 255, 255));
              }
            }
          }
        }
      }
    }
  }

  /// Verificar si un píxel está dentro de un número
  bool _isPixelInNumber(String num, int x, int y) {
    switch (num) {
      case '1':
        return x == 2;
      case '2':
        return (y == 0 || y == 7) || (y == 3 && x >= 1 && x <= 4) || (x == 0 || x == 4);
      case '3':
        return (y == 0 || y == 3 || y == 7) || (x == 0 || x == 4);
      case '4':
        return (x == 0 || x == 4) || (y >= 1 && y <= 5 && x >= 2 && x <= 4);
      case '5':
        return (y == 0 || y == 3 || y == 7) || (x == 0 || x == 4);
      case '6':
        return (y == 0 || y == 7) || (x == 0 || x == 4) || (y >= 3 && y <= 5 && x >= 2 && x <= 4);
      case '7':
        return (y == 0 && x <= 4) || (x == 4);
      case '8':
        return (y == 0 || y == 3 || y == 7) || (x == 0 || x == 4);
      case '9':
        return (y == 0 || y == 3 || y == 7) || (x == 0 || x == 4) || (y >= 1 && y <= 3 && x >= 2 && x <= 4);
      default:
        return false;
    }
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
