import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

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

  Future<DominoDetectionResult> detectDominoPoints(String imagePath) async {
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

      // 3. Probar ambas polaridades y elegir la mejor
      final darkDots = _detectBlobs(blurred, width, height, darkOnLight: true);
      final lightDots = _detectBlobs(blurred, width, height, darkOnLight: false);

      // Elegir el set que tenga más blobs consistentes (tamaño uniforme)
      final List<_Blob> chosen =
          _scoreBlobSet(darkDots) >= _scoreBlobSet(lightDots) ? darkDots : lightDots;

      // 4. Dibujar círculos sobre la imagen para visualización
      String? annotatedPath;
      if (chosen.isNotEmpty) {
        final annotated = img.Image.from(image);
        final green = img.ColorRgb8(0, 255, 0);
        for (final blob in chosen) {
          final radius = (sqrt(blob.area / pi)).round().clamp(4, 40);
          final cx = blob.centerX.round();
          final cy = blob.centerY.round();
          // Dibujar varios círculos concéntricos para simular grosor
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
        final tempDir = imageFile.parent.path;
        final ts = DateTime.now().millisecondsSinceEpoch;
        annotatedPath = '$tempDir/annotated_$ts.jpg';
        await File(annotatedPath).writeAsBytes(img.encodeJpg(annotated, quality: 85));
      }

      final totalPoints = chosen.length;

      return DominoDetectionResult(
        detectedPoints: totalPoints > 0 ? [totalPoints] : [],
        imagePath: imagePath,
        annotatedImagePath: annotatedPath,
        analysisInfo: totalPoints > 0
            ? 'Se detectaron $totalPoints puntos en la imagen'
            : 'No se detectaron puntos. Acerca más el dominó, mejora la iluminación y evita sombras.',
      );
    } catch (e) {
      debugPrint('Error detecting domino points: $e');
      return DominoDetectionResult(
        detectedPoints: [],
        imagePath: imagePath,
        analysisInfo: 'Error en el análisis: ${e.toString()}',
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
  List<_Blob> _detectBlobs(Uint8List lum, int width, int height,
      {required bool darkOnLight}) {
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

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final x0 = max(0, x - windowRadius);
        final y0 = max(0, y - windowRadius);
        final x1 = min(width - 1, x + windowRadius);
        final y1 = min(height - 1, y + windowRadius);

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

    // Flood-fill para encontrar blobs
    final List<int> labels = List.filled(width * height, -1);
    final List<_Blob> blobs = [];
    int labelId = 0;

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final idx = y * width + x;
        if (isFg[idx] && labels[idx] == -1) {
          final blob = _floodFill(isFg, labels, width, height, x, y, labelId);
          if (blob != null) blobs.add(blob);
          labelId++;
        }
      }
    }

    // Filtrar por tamaño y forma
    final double imageArea = width.toDouble() * height.toDouble();
    final double minBlobArea = imageArea * 0.0002;
    final double maxBlobArea = imageArea * 0.04;

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
    return showDialog<DominoDetectionResult>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D44),
          title: const Text(
            'Análisis de Puntos',
            style: TextStyle(
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
                const Text(
                  'No se detectaron puntos',
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Puntos detectados:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...result.detectedPoints.map((points) => Text(
                      '· $points puntos',
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
              child: const Text(
                'Cancelar',
                style: TextStyle(
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
                child: const Text(
                  'Usar estos puntos',
                  style: TextStyle(
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
