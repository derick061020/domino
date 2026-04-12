import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:math';
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
      final bytes = await imageFile.readAsBytes();
      img.Image? original = img.decodeImage(bytes);

      if (original == null) {
        throw Exception('No se pudo cargar la imagen');
      }

      img.Image image = original;
      if (image.width > 640) {
        image = img.copyResize(image, width: 640);
      }

      final int w = image.width;
      final int h = image.height;

      // ── DETECCIÓN DIRECTA EN RGB ──
      // Un punto negro de dominó tiene R, G, B todos bajos
      // y NO es un color oscuro (como marrón o azul marino).
      // Criterio: cada canal < umbral Y la diferencia entre canales es baja.

      // Leer RGB en arrays para acceso rápido
      final List<int> rr = List.filled(w * h, 0);
      final List<int> gg = List.filled(w * h, 0);
      final List<int> bb = List.filled(w * h, 0);

      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final p = image.getPixel(x, y);
          final int idx = y * w + x;
          rr[idx] = p.r.toInt();
          gg[idx] = p.g.toInt();
          bb[idx] = p.b.toInt();
        }
      }

      // Umbral para "negro": cada canal debe ser menor a esto.
      // 80 es bastante estricto — negro real.
      const int blackThresh = 85;
      // Máxima diferencia entre canales (para excluir colores oscuros)
      const int maxColorSpread = 50;

      final List<bool> isBlack = List.filled(w * h, false);
      for (int i = 0; i < w * h; i++) {
        final int r = rr[i];
        final int g = gg[i];
        final int b = bb[i];

        // Todos los canales deben ser bajos
        if (r > blackThresh || g > blackThresh || b > blackThresh) continue;

        // No debe ser un color oscuro (ej: rojo oscuro = R:80 G:10 B:10)
        final int maxC = max(r, max(g, b));
        final int minC = min(r, min(g, b));
        if (maxC - minC > maxColorSpread) continue;

        isBlack[i] = true;
      }

      // Flood-fill para agrupar píxeles negros en blobs
      final List<int> labels = List.filled(w * h, -1);
      final List<_Blob> blobs = [];
      int labelId = 0;

      for (int y = 1; y < h - 1; y++) {
        for (int x = 1; x < w - 1; x++) {
          final int idx = y * w + x;
          if (!isBlack[idx] || labels[idx] != -1) continue;
          final blob = _floodFill(isBlack, labels, w, h, x, y, labelId);
          labelId++;
          if (blob != null) blobs.add(blob);
        }
      }

      // Filtrar por forma circular y tamaño
      final double imgArea = w.toDouble() * h.toDouble();
      final double minArea = imgArea * 0.00005;
      final double maxArea = imgArea * 0.05;

      final List<_Blob> candidates = [];
      for (final b in blobs) {
        if (b.area < minArea || b.area > maxArea) continue;

        final double bboxArea = b.bboxW * b.bboxH.toDouble();
        if (bboxArea == 0) continue;

        // Circularidad (fill ratio)
        final double fill = b.area / bboxArea;
        if (fill < 0.55) continue;

        // Redondez (aspect ratio)
        final double ar = b.bboxW / b.bboxH;
        if (ar < 0.4 || ar > 2.5) continue;

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

      // Consistencia de tamaño
      final diameters = candidates.map((b) => sqrt(b.area)).toList()..sort();
      final double median = diameters[diameters.length ~/ 2];

      final List<_Blob> consistent = candidates.where((b) {
        final d = sqrt(b.area);
        return d > median * 0.35 && d < median * 2.5;
      }).toList();

      // Eliminar duplicados cercanos
      final List<_Blob> finalDots = [];
      for (final b in consistent) {
        bool duplicate = false;
        for (final existing in finalDots) {
          final dx = b.cx - existing.cx;
          final dy = b.cy - existing.cy;
          final dist = sqrt(dx * dx + dy * dy);
          final minDist = (sqrt(b.area) + sqrt(existing.area)) * 0.4;
          if (dist < minDist) {
            duplicate = true;
            break;
          }
        }
        if (!duplicate) finalDots.add(b);
      }

      // Anotar imagen
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

  _Blob? _floodFill(List<bool> mask, List<int> labels, int w, int h,
      int startX, int startY, int id) {
    final List<int> queue = [startY * w + startX];
    labels[startY * w + startX] = id;

    int area = 0, sumX = 0, sumY = 0;
    int minX = startX, maxX = startX, minY = startY, maxY = startY;

    int head = 0;
    while (head < queue.length) {
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
  //  UI: DIÁLOGO CON AJUSTE MANUAL
  // ─────────────────────────────────────────────────────

  Future<DominoDetectionResult?> showImageAnalysisDialog(
      BuildContext context, DominoDetectionResult result) async {
    final loc = AppLocalizations.of(context);
    final int detected =
        result.detectedPoints.isNotEmpty ? result.detectedPoints.first : 0;

    return showDialog<DominoDetectionResult>(
      context: context,
      builder: (_) => _AnalysisDialog(
        loc: loc,
        result: result,
        initialPoints: detected,
      ),
    );
  }
}

class _AnalysisDialog extends StatefulWidget {
  final AppLocalizations loc;
  final DominoDetectionResult result;
  final int initialPoints;

  const _AnalysisDialog({
    required this.loc,
    required this.result,
    required this.initialPoints,
  });

  @override
  State<_AnalysisDialog> createState() => _AnalysisDialogState();
}

class _AnalysisDialogState extends State<_AnalysisDialog> {
  late int _points;

  @override
  void initState() {
    super.initState();
    _points = widget.initialPoints;
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final result = widget.result;

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
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 200, maxWidth: 200),
                child: Image.file(
                  File(result.annotatedImagePath ?? result.imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFFE53935).withValues(alpha: 0.3)),
            ),
            child: Text(
              result.analysisInfo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            loc.get('detected_points'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleBtn(Icons.remove, () {
                if (_points > 0) setState(() => _points--);
              }),
              Container(
                width: 80,
                alignment: Alignment.center,
                child: Text(
                  '$_points',
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              _circleBtn(Icons.add, () {
                if (_points < 100) setState(() => _points++);
              }),
            ],
          ),
          Text(
            loc.get('points'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
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
        if (_points > 0)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(DominoDetectionResult(
                detectedPoints: [_points],
                imagePath: result.imagePath,
                annotatedImagePath: result.annotatedImagePath,
                analysisInfo: result.analysisInfo,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            child: Text(
              '${loc.get('use_these_points')} ($_points)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE53935), width: 2),
          ),
          child: Icon(icon, color: const Color(0xFFE53935), size: 28),
        ),
      ),
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
