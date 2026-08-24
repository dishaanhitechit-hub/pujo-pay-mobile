import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../shared/theme/app_theme.dart';

class QrScanLoginScreen extends StatefulWidget {
  const QrScanLoginScreen({super.key});
  @override
  State<QrScanLoginScreen> createState() => _State();
}

class _State extends State<QrScanLoginScreen> {
  final _ctrl = MobileScannerController();
  bool _scanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    if (!raw.startsWith('pujopay-login:')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR — not a PujoPay login code'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final email = raw.replaceFirst('pujopay-login:', '').trim();
    if (email.isEmpty) return;

    setState(() => _scanned = true);
    _ctrl.stop();
    Navigator.of(context).pop(email);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.navBg,
        title: const Text('Scan Login QR'),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _ctrl.toggleTorch(),
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(controller: _ctrl, onDetect: _onDetect),

        // Overlay with scan frame
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accent, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // Bottom instruction
        Positioned(
          bottom: 60,
          left: 0, right: 0,
          child: Column(children: [
            const Icon(Icons.qr_code_scanner, color: Colors.white54, size: 28),
            const SizedBox(height: 10),
            const Text(
              'Point camera at the\ncollector\'s login QR code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ]),
        ),
      ]),
    );
  }
}
