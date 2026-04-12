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

      // Redimensionar a ancho fijo para consistencia
      img.Image image = original;
      if (image.width > 640) {
        image = img.copyResize(image, width: 640);
      }

      final int w = image.width;
      final int h = image.height;

      // 1. Escala de grises
      final Uint8List gray = Uint8List(w * h);
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final p = image.getPixel(x, y);
          gray[y * w + x] =
              (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round().clamp(0, 255);
        }
      }

      // 2. Percentil 90 del brillo = referencia de "superficie de ficha"
      //    Usamos p90 porque con varias fichas la mesa oscura ocupa más
      //    y baja los percentiles inferiores. El p90 siempre captura
      //    la superficie blanca de las fichas.
      final List<int> sorted = List.of(gray)..sort();
      final int p90 = sorted[(sorted.length * 0.90).toInt()];
      // Un punto negro marcado debe estar por debajo del 60% del brillo
      // de la ficha. Si la ficha es ~200, el corte queda en ~120.
      final int absoluteMax = (p90 * 0.60).round().clamp(50, 150);

      // 3. Integral image para umbral adaptativo
      final List<int> integral = List.filled((w + 1) * (h + 1), 0);
      for (int y = 0; y < h; y++) {
        int rowSum = 0;
        for (int x = 0; x < w; x++) {
          rowSum += gray[y * w + x];
          integral[(y + 1) * (w + 1) + (x + 1)] =
              integral[y * (w + 1) + (x + 1)] + rowSum;
        }
      }

      // 4. Marcar píxeles que son NEGRO MUY MARCADO:
      //    - Deben ser oscuros en valor absoluto (< absoluteMax)
      //    - Deben ser más oscuros que su vecindario local
      final int winR = 20;
      const int adaptiveDelta = 18;

      final List<bool> isDark = List.filled(w * h, false);
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final int pixel = gray[y * w + x];

          // Filtro 1: debe ser oscuro en absoluto
          if (pixel > absoluteMax) continue;

          // Filtro 2: debe ser más oscuro que su entorno
          final int x0 = max(0, x - winR);
          final int y0 = max(0, y - winR);
          final int x1 = min(w - 1, x + winR);
          final int y1 = min(h - 1, y + winR);
          final int w1 = w + 1;
          final int sum = integral[(y1 + 1) * w1 + (x1 + 1)]
              - integral[y0 * w1 + (x1 + 1)]
              - integral[(y1 + 1) * w1 + x0]
              + integral[y0 * w1 + x0];
          final int area = (x1 - x0 + 1) * (y1 - y0 + 1);
          final double localMean = sum / area;

          if (pixel < localMean - adaptiveDelta) {
            isDark[y * w + x] = true;
          }
        }
      }

      // 6. Flood-fill para agrupar píxeles oscuros en blobs
      final List<int> labels = List.filled(w * h, -1);
      final List<_Blob> blobs = [];
      int labelId = 0;

      for (int y = 1; y < h - 1; y++) {
        for (int x = 1; x < w - 1; x++) {
          final int idx = y * w + x;
          if (!isDark[idx] || labels[idx] != -1) continue;

          final blob = _floodFill(isDark, labels, w, h, x, y, labelId);
          labelId++;
          if (blob != null) blobs.add(blob);
        }
      }

      // 7. Filtrar blobs por forma circular y tamaño razonable
      final double imgArea = w.toDouble() * h.toDouble();
      final double minArea = imgArea * 0.00008; // mínimo (varias fichas = puntos pequeños)
      final double maxArea = imgArea * 0.04;    // máximo

      final List<_Blob> candidates = [];
      for (final b in blobs) {
        if (b.area < minArea || b.area > maxArea) continue;

        final double bboxArea = b.bboxW * b.bboxH.toDouble();
        if (bboxArea == 0) continue;

        // Fill ratio: un círculo en su bbox tiene ~0.785
        final double fill = b.area / bboxArea;
        if (fill < 0.60) continue;

        // Aspect ratio: debe ser casi cuadrado (es un punto redondo)
        final double ar = b.bboxW / b.bboxH;
        if (ar < 0.5 || ar > 2.0) continue;

        // Verificar que el CENTRO del blob es realmente muy oscuro
        final int cx = b.cx.round().clamp(0, w - 1);
        final int cy = b.cy.round().clamp(0, h - 1);
        if (gray[cy * w + cx] > absoluteMax) continue;

        candidates.add(b);
      }

      if (candidates.isEmpty) {
        return DominoDetectionResult(
          detectedPoints: [],
          imagePath: imagePath,
          analysisInfo: loc != null
              ? loc.get('no_points_hint')
              : 'No se detectaron puntos.',
        );
      }

      // 8. Filtrar por consistencia de tamaño:
      //    Los puntos de un dominó son TODOS del mismo tamaño.
      //    Quedarnos solo con los que están cerca de la mediana.
      final diameters = candidates.map((b) => sqrt(b.area)).toList()..sort();
      final double median = diameters[diameters.length ~/ 2];

      final List<_Blob> consistent = candidates.where((b) {
        final d = sqrt(b.area);
        return d > median * 0.5 && d < median * 1.8;
      }).toList();

      // 9. Eliminar duplicados (blobs muy cercanos entre sí)
      final List<_Blob> finalDots = [];
      for (final b in consistent) {
        bool duplicate = false;
        for (final existing in finalDots) {
          final dx = b.cx - existing.cx;
          final dy = b.cy - existing.cy;
          final dist = sqrt(dx * dx + dy * dy);
          final minDist = (sqrt(b.area) + sqrt(existing.area)) * 0.5;
          if (dist < minDist) {
            duplicate = true;
            break;
          }
        }
        if (!duplicate) finalDots.add(b);
      }

      // 10. Dibujar círculos verdes sobre los puntos detectados
      String? annotatedPath;
      final annotated = img.Image.from(image);
      final green = img.ColorRgb8(0, 255, 0);

      for (final dot in finalDots) {
        final int r = (sqrt(dot.area / pi)).round().clamp(4, 40);
        final int px = dot.cx.round();
        final int py = dot.cy.round();
        for (int t = 0; t < 3; t++) {
          img.drawCircle(annotated,
              x: px, y: py, radius: r + 2 + t, color: green);
        }
      }

      final tempDir = imageFile.parent.path;
      final ts = DateTime.now().millisecondsSinceEpoch;
      annotatedPath = '$tempDir/annotated_$ts.jpg';
      await File(annotatedPath)
          .writeAsBytes(img.encodeJpg(annotated, quality: 90));

      final int total = finalDots.length;
      final String info = total > 0
          ? (loc != null
              ? loc.get('detected_n_points').replaceAll('%d', '$total')
              : 'Se detectaron $total puntos')
          : (loc != null
              ? loc.get('no_points_hint')
              : 'No se detectaron puntos.');

      return DominoDetectionResult(
        detectedPoints: total > 0 ? [total] : [],
        imagePath: imagePath,
        annotatedImagePath: annotatedPath,
        analysisInfo: info,
      );
    } catch (e) {
      debugPrint('Error detecting domino points: $e');
      final errorLabel =
          loc != null ? loc.get('analysis_error') : 'Analysis error';
      return DominoDetectionResult(
        detectedPoints: [],
        imagePath: imagePath,
        analysisInfo: '$errorLabel: ${e.toString()}',
      );
    }
  }

  // ─────────────────────────────────────────────────────

  _Blob? _floodFill(List<bool> mask, List<int> labels, int w, int h,
      int startX, int startY, int id) {
    final List<int> queue = [startY * w + startX];
    labels[startY * w + startX] = id;

    int area = 0, sumX = 0, sumY = 0;
    int minX = startX, maxX = startX, minY = startY, maxY = startY;

    int head = 0;
    while (head < queue.length) {
      // Limitar para no explotar en zonas enormes (no es un punto)
      if (area > 5000) return null;

      final int idx = queue[head++];
      final int x = idx % w;
      final int y = idx ~/ w;

      area++;
      sumX += x;
      sumY += y;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;

      if (x > 0) {
        final int n = idx - 1;
        if (mask[n] && labels[n] == -1) { labels[n] = id; queue.add(n); }
      }
      if (x < w - 1) {
        final int n = idx + 1;
        if (mask[n] && labels[n] == -1) { labels[n] = id; queue.add(n); }
      }
      if (y > 0) {
        final int n = idx - w;
        if (mask[n] && labels[n] == -1) { labels[n] = id; queue.add(n); }
      }
      if (y < h - 1) {
        final int n = idx + w;
        if (mask[n] && labels[n] == -1) { labels[n] = id; queue.add(n); }
      }
    }

    if (area < 4) return null;

    return _Blob(
      cx: sumX / area,
      cy: sumY / area,
      area: area.toDouble(),
      minX: minX, maxX: maxX, minY: minY, maxY: maxY,
    );
  }

  // ─────────────────────────────────────────────────────
  //  UI: DIÁLOGO DE ANÁLISIS
  // ─────────────────────────────────────────────────────

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
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 220, maxWidth: 220),
                    child: Image.file(
                      File(result.annotatedImagePath ?? result.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFE53935).withValues(alpha: 0.3)),
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
                onPressed: () => Navigator.of(context).pop(result),
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
  final double cx, cy, area;
  final int minX, maxX, minY, maxY;

  _Blob({
    required this.cx, required this.cy, required this.area,
    required this.minX, required this.maxX,
    required this.minY, required this.maxY,
  });

  int get bboxW => maxX - minX + 1;
  int get bboxH => maxY - minY + 1;
}
