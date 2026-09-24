import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:paylite/features/scan/data/qr_parser.dart';
import 'package:paylite/features/vpa/state/vpa_lookup_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  MobileScannerController? _controller;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;

    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final parsed = QrParser.parse(raw);

    if (parsed == null) {
      _showInvalid();
      return;
    }

    setState(() => _processing = true);
    await _controller?.stop();

    // Navigate to pay screen with parsed data
    if (mounted) {
      ref.read(parsedQrProvider.notifier).set(parsed);
      context.goNamed('pay', pathParameters: {}, extra: parsed);
    }
  }

  void _showInvalid() {
    setState(() => _processing = true);
    _controller?.stop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Invalid QR'),
        content: const Text(
          'This QR was detected, but it is not a valid UPI payment QR.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _processing = false);
              _controller?.start();
            },
            child: const Text('Scan again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
      ),
    );
  }
}   