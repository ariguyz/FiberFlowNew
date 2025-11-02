import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart'; // 👈 เพิ่ม

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
    detectionSpeed: DetectionSpeed.normal,
    returnImage: false,
  );

  bool _hasPermission = false;
  bool _processing = false; // กันสแกนซ้ำ
  bool _permanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _hasPermission = true);
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _permanentlyDenied = true;
        _hasPermission = false;
      });
    } else {
      if (mounted) Navigator.of(context).pop(); // ปิดหน้าถ้าไม่ให้สิทธิ์
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isHttpUrl(String s) {
    final u = Uri.tryParse(s);
    return u != null && (u.scheme == 'http' || u.scheme == 'https');
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    // เปิดด้วยแอปภายนอก (เบราว์เซอร์)
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่สามารถเปิดลิงก์ได้')));
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _processing = true;
    HapticFeedback.lightImpact();

    if (_isHttpUrl(code)) {
      // ✅ เป็น URL → เปิดทันที แล้วปิดหน้าสแกน
      await _openUrl(code);
      if (mounted) Navigator.pop(context);
    } else {
      // ❑ ไม่ใช่ URL → ส่งค่ากลับให้หน้าเดิมไปจัดการต่อ
      if (mounted) Navigator.pop(context, code);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_permanentlyDenied) {
      return Scaffold(
        appBar: AppBar(title: const Text('สแกน QR / Barcode')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_outlined, size: 64),
                const SizedBox(height: 12),
                const Text(
                  'ไม่ได้รับสิทธิ์กล้องแบบถาวร',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'โปรดเปิดสิทธิ์กล้องใน Settings > Apps > Permissions แล้วกลับมาใหม่',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => openAppSettings(),
                  child: const Text('เปิดหน้า Settings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกน QR / Barcode'),
        actions: [
          ValueListenableBuilder<TorchState>(
            valueListenable: _controller.torchState,
            builder: (context, state, _) {
              final isOn = state == TorchState.on;
              return IconButton(
                tooltip: isOn ? 'ปิดไฟฉาย' : 'เปิดไฟฉาย',
                icon: Icon(isOn ? Icons.flash_on : Icons.flash_off),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
          IconButton(
            tooltip: 'สลับกล้อง',
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // กล้อง
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'ไม่สามารถเปิดกล้องได้: ${error.errorCode.name}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),

          // มาส์กมืด + กรอบสแกน
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScannerOverlayPainter(
                  borderColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),

          // ข้อความช่วย
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'จัด QR/Barcode ให้อยู่ในกรอบเพื่อสแกน',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({required this.borderColor});
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    const frameSize = Size(240, 240);
    final center = size.center(Offset.zero);
    final rect = Rect.fromCenter(
      center: center,
      width: frameSize.width,
      height: frameSize.height,
    );

    final overlay =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole =
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
    final mask = Path.combine(PathOperation.difference, overlay, hole);
    canvas.drawPath(mask, Paint()..color = Colors.black.withOpacity(.55));

    final paint =
        Paint()
          ..color = borderColor
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;

    const corner = 26.0;
    // บนซ้าย
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(corner, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(0, corner), paint);
    // บนขวา
    canvas.drawLine(rect.topRight, rect.topRight.translate(-corner, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight.translate(0, corner), paint);
    // ล่างซ้าย
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft.translate(corner, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft.translate(0, -corner),
      paint,
    );
    // ล่างขวา
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight.translate(-corner, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight.translate(0, -corner),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor;
  }
}
