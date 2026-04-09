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

  DominoDetectionResult({
    required this.detectedPoints,
    required this.imagePath,
    required this.analysisInfo,
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

  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      return image?.path;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  Future<DominoDetectionResult> detectDominoPoints(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('No se pudo cargar la imagen');
      }

      // Redimensionar para procesamiento más rápido y consistente
      if (image.width > 800) {
        image = img.copyResize(image, width: 800);
      }

      // Detectar puntos oscuros (los puntos del dominó son oscuros sobre fondo claro)
      final dots = _detectDarkDots(image);

      final totalPoints = dots.length;

      return DominoDetectionResult(
        detectedPoints: totalPoints > 0 ? [totalPoints] : [],
        imagePath: imagePath,
        analysisInfo: totalPoints > 0
            ? 'Se detectaron $totalPoints puntos en la imagen'
            : 'No se detectaron puntos. Asegúrate de que la foto tenga buena iluminación y los puntos del dominó sean visibles.',
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

  /// Detecta puntos oscuros (dots del dominó) usando detección de blobs
  List<_Blob> _detectDarkDots(img.Image image) {
    final width = image.width;
    final height = image.height;

    // 1. Convertir a luminancia
    final List<int> lum = List.filled(width * height, 0);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        // Luminancia perceptual
        lum[y * width + x] = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();
      }
    }

    // 2. Calcular umbral adaptativo usando media local con ventana
    final int blockSize = max(width, height) ~/ 8;
    final List<bool> isDark = List.filled(width * height, false);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Calcular media local
        int sum = 0;
        int count = 0;
        final int x0 = max(0, x - blockSize);
        final int x1 = min(width - 1, x + blockSize);
        final int y0 = max(0, y - blockSize);
        final int y1 = min(height - 1, y + blockSize);

        // Muestrear en pasos para rendimiento
        for (int sy = y0; sy <= y1; sy += 4) {
          for (int sx = x0; sx <= x1; sx += 4) {
            sum += lum[sy * width + sx];
            count++;
          }
        }

        final double localMean = sum / count;
        final int pixelLum = lum[y * width + x];

        // Un píxel es "oscuro" si está significativamente por debajo de la media local
        isDark[y * width + x] = pixelLum < localMean - 30;
      }
    }

    // 3. Encontrar blobs conectados usando flood-fill
    final List<int> labels = List.filled(width * height, -1);
    final List<_Blob> blobs = [];
    int labelId = 0;

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final idx = y * width + x;
        if (isDark[idx] && labels[idx] == -1) {
          // Flood-fill para encontrar todo el blob
          final blob = _floodFill(isDark, labels, width, height, x, y, labelId);
          if (blob != null) {
            blobs.add(blob);
          }
          labelId++;
        }
      }
    }

    // 4. Filtrar blobs por tamaño y forma (circularidad)
    final double imageArea = width.toDouble() * height.toDouble();
    final double minBlobArea = imageArea * 0.0003; // mínimo 0.03% de la imagen
    final double maxBlobArea = imageArea * 0.03;   // máximo 3% de la imagen

    final List<_Blob> validDots = [];
    for (final blob in blobs) {
      if (blob.area < minBlobArea || blob.area > maxBlobArea) continue;

      // Verificar circularidad: ratio entre area y area del bounding box
      final double bboxArea = blob.bboxWidth * blob.bboxHeight.toDouble();
      if (bboxArea == 0) continue;

      final double fillRatio = blob.area / bboxArea;
      if (fillRatio < 0.4) continue; // Muy poco relleno, no es un punto

      // Verificar que el bounding box sea aproximadamente cuadrado
      final double aspectRatio = blob.bboxWidth / blob.bboxHeight;
      if (aspectRatio < 0.3 || aspectRatio > 3.0) continue; // Muy alargado

      validDots.add(blob);
    }

    // 5. Filtrar blobs que estén muy cerca (duplicados)
    return _filterNearbyBlobs(validDots);
  }

  _Blob? _floodFill(List<bool> isDark, List<int> labels, int width, int height,
      int startX, int startY, int labelId) {
    final queue = <int>[];
    final startIdx = startY * width + startX;
    queue.add(startIdx);
    labels[startIdx] = labelId;

    int area = 0;
    int sumX = 0, sumY = 0;
    int minX = startX, maxX = startX;
    int minY = startY, maxY = startY;

    // Limitar el tamaño del flood fill para evitar procesar regiones enormes
    const int maxFloodSize = 5000;

    int head = 0;
    while (head < queue.length) {
      if (area > maxFloodSize) return null; // Región demasiado grande, no es un punto

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
      for (final d in [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
        final nx = x + d[0];
        final ny = y + d[1];
        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
        final nIdx = ny * width + nx;
        if (isDark[nIdx] && labels[nIdx] == -1) {
          labels[nIdx] = labelId;
          queue.add(nIdx);
        }
      }
    }

    if (area < 5) return null; // Muy pequeño, es ruido

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
        final minDist = (sqrt(blob.area) + sqrt(existing.area)) * 0.3;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mostrar la imagen capturada
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Image.file(
                    File(result.imagePath),
                    fit: BoxFit.cover,
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
