import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../shared/theme/app_theme.dart';

class QrScanLoginScreen extends StatefulWidget {
  const QrScanLoginScreen({super.key});
  @override
  State<QrScanLoginScreen> createState() => _State();
}

enum _CamState { checking, granted, denied, permanentlyDenied }

class _State extends State<QrScanLoginScreen> {
  // Built only once permission is confirmed, so the camera is never bound
  // before the grant has landed.
  MobileScannerController? _ctrl;
  _CamState _camState = _CamState.checking;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() => _camState = _CamState.checking);

    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      _ctrl = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode],
      );
      setState(() => _camState = _CamState.granted);
    } else if (status.isPermanentlyDenied) {
      setState(() => _camState = _CamState.permanentlyDenied);
    } else {
      setState(() => _camState = _CamState.denied);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned || capture.barcodes.isEmpty) return;

    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

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
    Navigator.of(context).pop(email);
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
          if (_camState == _CamState.granted)
            IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white),
              onPressed: () => _ctrl?.toggleTorch(),
            ),
        ],
      ),
      body: switch (_camState) {
        _CamState.checking => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        _CamState.granted => _ScannerView(
            ctrl: _ctrl!,
            onDetect: _onDetect,
            onRetry: _restart,
          ),
        _CamState.denied => _MessageView(
            message: 'Camera permission was denied.\nPlease allow it to scan.',
            onRetry: _checkPermission,
            onBack: () => Navigator.of(context).pop(null),
          ),
        _CamState.permanentlyDenied => _MessageView(
            message:
                'Camera permission is permanently denied.\nOpen Settings to allow it.',
            settingsButton: true,
            onBack: () => Navigator.of(context).pop(null),
          ),
      },
    );
  }

  /// Tears the controller down and builds a fresh one — a half-initialised
  /// camera cannot be recovered by calling start() again.
  Future<void> _restart() async {
    final old = _ctrl;
    _ctrl = null;
    if (mounted) setState(() => _camState = _CamState.checking);
    await old?.dispose();
    if (!mounted) return;
    await _checkPermission();
  }
}

// ── Scanner view ──────────────────────────────────────────────────────────────

class _ScannerView extends StatelessWidget {
  final MobileScannerController ctrl;
  final void Function(BarcodeCapture) onDetect;
  final Future<void> Function() onRetry;
  const _ScannerView({
    required this.ctrl,
    required this.onDetect,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      MobileScanner(
        controller: ctrl,
        onDetect: onDetect,
        placeholderBuilder: (_) => const ColoredBox(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        ),
        errorBuilder: (ctx, error) => _MessageView(
          message: _describe(error),
          detail: kDebugMode ? error.toString() : error.errorDetails?.message,
          onRetry: onRetry,
          onBack: () => Navigator.of(ctx).pop(null),
        ),
      ),
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
      const Positioned(
        bottom: 60,
        left: 0,
        right: 0,
        child: Column(children: [
          Icon(Icons.qr_code_scanner, color: Colors.white54, size: 28),
          SizedBox(height: 10),
          Text(
            "Point camera at the\ncollector's login QR code",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ]),
      ),
    ]);
  }

  static String _describe(MobileScannerException e) => switch (e.errorCode) {
        MobileScannerErrorCode.permissionDenied =>
          'Camera permission was denied.',
        MobileScannerErrorCode.unsupported =>
          'Scanning is not supported on this device.',
        MobileScannerErrorCode.controllerAlreadyInitialized =>
          'Camera was already running.\nTap Try Again.',
        MobileScannerErrorCode.controllerDisposed ||
        MobileScannerErrorCode.controllerUninitialized ||
        MobileScannerErrorCode.controllerInitializing =>
          'Camera is still starting up.\nTap Try Again.',
        _ => 'Could not start the camera.',
      };
}

// ── Message / error UI ────────────────────────────────────────────────────────

class _MessageView extends StatelessWidget {
  final String message;
  final String? detail;
  final bool settingsButton;
  final VoidCallback? onBack;
  final Future<void> Function()? onRetry;
  const _MessageView({
    required this.message,
    this.detail,
    this.settingsButton = false,
    this.onBack,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          if (detail != null && detail!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              detail!,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 28),
          if (settingsButton)
            ElevatedButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Open Settings'),
              style: _btn,
            ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => onRetry!(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: _btn,
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: onBack,
            child: const Text('Go Back', style: TextStyle(color: Colors.white60)),
          ),
        ]),
      ),
    );
  }

  static final ButtonStyle _btn = ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
