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

      // Redimensionar para procesamiento consistente
      img.Image image = original;
      if (image.width > 800) {
        image = img.copyResize(image, width: 800);
      }

      final width = image.width;
      final height = image.height;

      // 1. Convertir a escala de grises (luminancia)
      final Uint8List lum = Uint8List(width * height);
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final p = image.getPixel(x, y);
          lum[y * width + x] =
              (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round().clamp(0, 255);
        }
      }

      // 2. Blur para reducir ruido (5x5 box blur)
      final Uint8List blurred = _boxBlur5(lum, width, height);

      // 3. Encontrar la ficha de dominó (región blanca/clara rectangular)
      final _Rect? tileRect = _findDominoTile(blurred, width, height);

      // 4. Definir ROI: la ficha detectada o toda la imagen
      final _Rect roi = tileRect ??
          _Rect(x0: 0, y0: 0, x1: width - 1, y1: height - 1);

      // 5. Detectar SOLO puntos negros/oscuros dentro del ROI
      final List<_Blob> darkDots =
          _detectDarkDots(blurred, width, height, roi);

      // 6. Anotar imagen con resultados
      String? annotatedPath;
      final annotated = img.Image.from(image);

      if (tileRect != null) {
        final blue = img.ColorRgb8(0, 150, 255);
        for (int t = 0; t < 3; t++) {
          img.drawRect(annotated,
              x1: (tileRect.x0 - t).clamp(0, width - 1),
              y1: (tileRect.y0 - t).clamp(0, height - 1),
              x2: (tileRect.x1 + t).clamp(0, width - 1),
              y2: (tileRect.y1 + t).clamp(0, height - 1),
              color: blue);
        }
      }

      if (darkDots.isNotEmpty) {
        final green = img.ColorRgb8(0, 255, 0);
        for (final blob in darkDots) {
          final radius = (sqrt(blob.area / pi)).round().clamp(4, 40);
          final cx = blob.centerX.round();
          final cy = blob.centerY.round();
          for (int t = 0; t < 3; t++) {
            img.drawCircle(annotated,
                x: cx, y: cy, radius: radius + 2 + t, color: green);
          }
        }
      }

      if (tileRect != null || darkDots.isNotEmpty) {
        final tempDir = imageFile.parent.path;
        final ts = DateTime.now().millisecondsSinceEpoch;
        annotatedPath = '$tempDir/annotated_$ts.jpg';
        await File(annotatedPath)
            .writeAsBytes(img.encodeJpg(annotated, quality: 85));
      }

      final totalPoints = darkDots.length;

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
      final errorLabel =
          loc != null ? loc.get('analysis_error') : 'Analysis error';
      return DominoDetectionResult(
        detectedPoints: [],
        imagePath: imagePath,
        analysisInfo: '$errorLabel: ${e.toString()}',
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PASO 1: ENCONTRAR LA FICHA (rectángulo blanco/claro)
  // ──────────────────────────────────────────────────────────────────────────

  /// Usa Otsu para binarizar, busca la región clara más grande que sea
  /// rectangular. Las fichas de dominó son blancas/marfil → siempre claras.
  _Rect? _findDominoTile(Uint8List lum, int width, int height) {
    final int threshold = _otsuThreshold(lum);

    // Binarizar: píxeles claros = foreground (la ficha)
    final List<bool> isBright = List.filled(lum.length, false);
    for (int i = 0; i < lum.length; i++) {
      isBright[i] = lum[i] > threshold;
    }

    // Erosión + dilatación (closing) para limpiar huecos
    // Los puntos negros dentro de la ficha crean agujeros; los cerramos
    final List<bool> closed = _morphClose(isBright, width, height, radius: 5);

    // Flood-fill para encontrar blobs grandes
    final List<int> labels = List.filled(lum.length, -1);
    int labelId = 0;
    _Blob? bestTile;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        if (closed[idx] && labels[idx] == -1) {
          final blob =
              _largeFloodFill(closed, labels, width, height, x, y, labelId);
          labelId++;
          if (blob == null) continue;

          final double imageArea = width.toDouble() * height.toDouble();
          // La ficha debe ocupar al menos el 3% de la imagen
          if (blob.area < imageArea * 0.03) continue;
          // Pero no más del 95%
          if (blob.area > imageArea * 0.95) continue;

          final int bw = blob.bboxWidth;
          final int bh = blob.bboxHeight;
          if (bw < 15 || bh < 15) continue;

          // Aspect ratio de ficha: entre 0.25 (doble 6 horizontal) y 4.0
          final double ar = bw / bh;
          if (ar < 0.25 || ar > 4.0) continue;

          // Fill ratio: qué tan lleno está el bbox
          final double bboxArea = bw.toDouble() * bh.toDouble();
          final double fillRatio = blob.area / bboxArea;
          if (fillRatio < 0.55) continue;

          // Preferir el blob más grande y rectangular
          if (bestTile == null || blob.area > bestTile.area) {
            bestTile = blob;
          }
        }
      }
    }

    if (bestTile == null) return null;

    // Margen interno de 4px para evitar borde de la ficha
    const int pad = 4;
    return _Rect(
      x0: (bestTile.minX + pad).clamp(0, width - 1),
      y0: (bestTile.minY + pad).clamp(0, height - 1),
      x1: (bestTile.maxX - pad).clamp(0, width - 1),
      y1: (bestTile.maxY - pad).clamp(0, height - 1),
    );
  }

  /// Threshold de Otsu: encuentra el umbral que maximiza la varianza entre
  /// las dos clases (claro/oscuro).
  int _otsuThreshold(Uint8List lum) {
    final List<int> hist = List.filled(256, 0);
    for (int i = 0; i < lum.length; i++) {
      hist[lum[i]]++;
    }

    final int total = lum.length;
    double sumAll = 0;
    for (int i = 0; i < 256; i++) {
      sumAll += i * hist[i];
    }

    double sumBg = 0;
    int wBg = 0;
    double maxVariance = 0;
    int bestThreshold = 128;

    for (int t = 0; t < 256; t++) {
      wBg += hist[t];
      if (wBg == 0) continue;
      final int wFg = total - wBg;
      if (wFg == 0) break;

      sumBg += t * hist[t];
      final double meanBg = sumBg / wBg;
      final double meanFg = (sumAll - sumBg) / wFg;
      final double diff = meanBg - meanFg;
      final double variance = diff * diff * wBg * wFg;

      if (variance > maxVariance) {
        maxVariance = variance;
        bestThreshold = t;
      }
    }

    return bestThreshold;
  }

  /// Cierre morfológico: dilatar y luego erosionar.
  /// Cierra agujeros pequeños (como los puntos negros dentro de la ficha).
  List<bool> _morphClose(List<bool> input, int width, int height,
      {required int radius}) {
    // Dilatar
    final List<bool> dilated = List.filled(input.length, false);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (!input[y * width + x]) continue;
        for (int dy = -radius; dy <= radius; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= height) continue;
          for (int dx = -radius; dx <= radius; dx++) {
            final nx = x + dx;
            if (nx < 0 || nx >= width) continue;
            if (dx * dx + dy * dy <= radius * radius) {
              dilated[ny * width + nx] = true;
            }
          }
        }
      }
    }

    // Erosionar
    final List<bool> eroded = List.filled(input.length, true);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (dilated[y * width + x]) continue;
        for (int dy = -radius; dy <= radius; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= height) continue;
          for (int dx = -radius; dx <= radius; dx++) {
            final nx = x + dx;
            if (nx < 0 || nx >= width) continue;
            if (dx * dx + dy * dy <= radius * radius) {
              eroded[ny * width + nx] = false;
            }
          }
        }
      }
    }

    return eroded;
  }

  /// Flood-fill sin límite de tamaño (para encontrar la ficha entera).
  _Blob? _largeFloodFill(List<bool> isFg, List<int> labels, int width,
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

      for (final n in [idx - 1, idx + 1, idx - width, idx + width]) {
        if (n >= 0 && n < labels.length && isFg[n] && labels[n] == -1) {
          final nx = n % width;
          // Evitar wrap-around horizontal
          if ((n == idx - 1 && nx == width - 1) ||
              (n == idx + 1 && nx == 0)) {
            continue;
          }
          labels[n] = labelId;
          queue.add(n);
        }
      }
    }

    if (area < 200) return null;

    return _Blob(
      centerX: sumX / area,
      centerY: sumY / area,
      area: area.toDouble(),
      minX: minX, maxX: maxX, minY: minY, maxY: maxY,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PASO 2: DETECTAR PUNTOS NEGROS DENTRO DE LA FICHA
  // ──────────────────────────────────────────────────────────────────────────

  /// Detecta solo puntos OSCUROS dentro del ROI usando umbral adaptativo.
  /// Verifica que cada candidato sea realmente oscuro en valor absoluto.
  List<_Blob> _detectDarkDots(
      Uint8List lum, int width, int height, _Rect roi) {
    // Integral image (para toda la imagen, luego consultamos solo en ROI)
    final List<int> integral = List.filled((width + 1) * (height + 1), 0);
    for (int y = 0; y < height; y++) {
      int rowSum = 0;
      for (int x = 0; x < width; x++) {
        rowSum += lum[y * width + x];
        integral[(y + 1) * (width + 1) + (x + 1)] =
            integral[y * (width + 1) + (x + 1)] + rowSum;
      }
    }

    // Calcular brillo medio dentro del ROI (para verificación absoluta)
    final int roiSum = _integralSum(integral, width, roi.x0, roi.y0, roi.x1, roi.y1);
    final int roiPixels = roi.width * roi.height;
    final double roiMean = roiSum / roiPixels;

    // Umbral adaptativo: un punto es oscuro si está significativamente
    // por debajo de la media local
    final int windowRadius = max(12, min(roi.width, roi.height) ~/ 8);
    const int threshDelta = 20;

    // Umbral absoluto: el píxel también debe estar por debajo de este valor
    // para ser considerado "negro". Es relativo al brillo medio del ROI.
    final int absoluteMaxBrightness = (roiMean * 0.75).round().clamp(60, 200);

    final List<bool> isDark = List.filled(width * height, false);

    for (int y = roi.y0; y <= roi.y1; y++) {
      for (int x = roi.x0; x <= roi.x1; x++) {
        final int pixel = lum[y * width + x];

        // Filtro absoluto: debe ser oscuro en valor absoluto
        if (pixel > absoluteMaxBrightness) continue;

        // Filtro adaptativo: debe ser oscuro relativo a su vecindario
        final int wx0 = max(0, x - windowRadius);
        final int wy0 = max(0, y - windowRadius);
        final int wx1 = min(width - 1, x + windowRadius);
        final int wy1 = min(height - 1, y + windowRadius);

        final int sum =
            _integralSum(integral, width, wx0, wy0, wx1, wy1);
        final int area = (wx1 - wx0 + 1) * (wy1 - wy0 + 1);
        final double localMean = sum / area;

        if (pixel < localMean - threshDelta) {
          isDark[y * width + x] = true;
        }
      }
    }

    // Flood-fill para agrupar píxeles oscuros en blobs
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
        if (isDark[idx] && labels[idx] == -1) {
          final blob = _dotFloodFill(isDark, labels, width, height, x, y, labelId);
          if (blob != null) blobs.add(blob);
          labelId++;
        }
      }
    }

    // Filtrar por tamaño y circularidad
    final double roiArea = roi.width.toDouble() * roi.height.toDouble();
    final double minDotArea = roiArea * 0.0008; // al menos 0.08% del ROI
    final double maxDotArea = roiArea * 0.06;   // máximo 6% del ROI

    final List<_Blob> candidates = [];
    for (final blob in blobs) {
      if (blob.area < minDotArea || blob.area > maxDotArea) continue;

      final double bboxArea = blob.bboxWidth * blob.bboxHeight.toDouble();
      if (bboxArea == 0) continue;

      // Fill ratio: un círculo tiene ~0.785
      final double fillRatio = blob.area / bboxArea;
      if (fillRatio < 0.50) continue;

      // Aspect ratio: debe ser casi cuadrado
      final double aspectRatio = blob.bboxWidth / blob.bboxHeight;
      if (aspectRatio < 0.5 || aspectRatio > 2.0) continue;

      // Verificar que el centro del blob es realmente oscuro
      final int cx = blob.centerX.round().clamp(0, width - 1);
      final int cy = blob.centerY.round().clamp(0, height - 1);
      final int centerBrightness = lum[cy * width + cx];
      if (centerBrightness > absoluteMaxBrightness) continue;

      candidates.add(blob);
    }

    if (candidates.isEmpty) return [];

    // Filtrar por consistencia de tamaño entre todos los puntos
    final diameters = candidates.map((b) => sqrt(b.area)).toList()..sort();
    final double medianDiam = diameters[diameters.length ~/ 2];

    final List<_Blob> consistent = candidates.where((b) {
      final d = sqrt(b.area);
      return d > medianDiam * 0.45 && d < medianDiam * 2.0;
    }).toList();

    // Eliminar blobs duplicados (muy cercanos)
    return _filterNearbyBlobs(consistent);
  }

  /// Consulta de suma en la integral image.
  int _integralSum(List<int> integral, int imgWidth,
      int x0, int y0, int x1, int y1) {
    final int w1 = imgWidth + 1;
    return integral[(y1 + 1) * w1 + (x1 + 1)]
        - integral[y0 * w1 + (x1 + 1)]
        - integral[(y1 + 1) * w1 + x0]
        + integral[y0 * w1 + x0];
  }

  /// Flood-fill para puntos (con límite de tamaño).
  _Blob? _dotFloodFill(List<bool> isFg, List<int> labels, int width,
      int height, int startX, int startY, int labelId) {
    final queue = <int>[];
    final startIdx = startY * width + startX;
    queue.add(startIdx);
    labels[startIdx] = labelId;

    int area = 0;
    int sumX = 0, sumY = 0;
    int minX = startX, maxX = startX;
    int minY = startY, maxY = startY;

    const int maxDotSize = 6000;

    int head = 0;
    while (head < queue.length) {
      if (area > maxDotSize) return null;

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

      // 4 vecinos con boundary check
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

    if (area < 6) return null;

    return _Blob(
      centerX: sumX / area,
      centerY: sumY / area,
      area: area.toDouble(),
      minX: minX, maxX: maxX, minY: minY, maxY: maxY,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UTILIDADES
  // ──────────────────────────────────────────────────────────────────────────

  /// Box blur 5x5 para mejor reducción de ruido.
  Uint8List _boxBlur5(Uint8List lum, int width, int height) {
    final Uint8List out = Uint8List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int sum = 0;
        int count = 0;
        for (int dy = -2; dy <= 2; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= height) continue;
          for (int dx = -2; dx <= 2; dx++) {
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

  List<_Blob> _filterNearbyBlobs(List<_Blob> blobs) {
    final List<_Blob> filtered = [];
    for (final blob in blobs) {
      bool tooClose = false;
      for (final existing in filtered) {
        final dx = blob.centerX - existing.centerX;
        final dy = blob.centerY - existing.centerY;
        final distance = sqrt(dx * dx + dy * dy);
        final minDist = (sqrt(blob.area) + sqrt(existing.area)) * 0.4;
        if (distance < minDist) {
          tooClose = true;
          break;
        }
      }
      if (!tooClose) filtered.add(blob);
    }
    return filtered;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UI: DIÁLOGO DE ANÁLISIS
  // ──────────────────────────────────────────────────────────────────────────

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

// ────────────────────────────────────────────────────────────────────────────
// MODELOS INTERNOS
// ────────────────────────────────────────────────────────────────────────────

class _Blob {
  final double centerX, centerY, area;
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
