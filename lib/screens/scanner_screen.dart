import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/scan_history_entry.dart';
import '../models/scene_asset.dart';
import '../services/api_service.dart';
import '../services/scan_history_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glitch_button.dart';
import '../widgets/glitch_text.dart';
import '../widgets/scanner_reticle.dart';
import '../widgets/terminal_scan_overlay.dart';
import 'history_screen.dart';
import 'result_screen.dart';

enum _ScanState { idle, scanning }

/// Full-screen camera scanner: live preview, digital reticle overlay and a
/// capture flow that plays a CLI-style processing animation before the
/// photo is handed off to [ApiService].
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  Future<SceneAsset>? _uploadFuture;
  _ScanState _scanState = _ScanState.idle;
  String? _errorMessage;

  static const _scanLines = [
    'BAĞLANTI KURULUYOR: LOCAL_SENSOR_ARRAY...',
    'ORTAM VERİSİ ALINIYOR...',
    'IŞIKLANDIRMA HARİTASI ÇIKARILIYOR...',
    'GÖRÜNTÜ BASE64 FORMATINA KODLANIYOR...',
    'SUNUCUYA GÖNDERİLİYOR: MESHY AI PIPELINE...',
  ];

  @override
  void initState() {
    super.initState();
    _initFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) setState(() => _errorMessage = 'KAMERA ERİŞİMİ REDDEDİLDİ.');
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _errorMessage = 'KAMERA BULUNAMADI.');
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'KAMERA BAŞLATILAMADI.');
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _scanState == _ScanState.scanning) {
      return;
    }

    Future<SceneAsset> uploadFuture;
    try {
      final file = await controller.takePicture();
      uploadFuture = ApiService.uploadSceneCapture(File(file.path));
    } catch (_) {
      uploadFuture = Future<SceneAsset>.error(ApiException('FOTOĞRAF ÇEKİLEMEDİ.'));
    }

    if (!mounted) return;
    setState(() {
      _scanState = _ScanState.scanning;
      _uploadFuture = uploadFuture;
    });
  }

  void _handleScanFinished(SceneAsset? asset, Object? error) {
    if (!mounted) return;
    setState(() {
      _scanState = _ScanState.idle;
      _uploadFuture = null;
    });

    if (asset != null) {
      if (asset.modelUrl != null) {
        unawaited(ScanHistoryService.add(ScanHistoryEntry.fromAsset(asset)));
      }
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultScreen(asset: asset)));
    } else {
      _showScanError(error is ApiException ? error.message : 'TARAMA BAŞARISIZ: $error');
    }
  }

  void _showScanError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.nearBlack,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.neonRed),
          borderRadius: BorderRadius.zero,
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.neonRed, fontFamily: 'monospace', fontSize: 13),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCameraLayer(),
            const Center(child: ScannerReticle()),
            _buildTopBar(),
            _buildBottomBar(),
            if (_scanState == _ScanState.scanning && _uploadFuture != null)
              TerminalScanOverlay(
                processingLines: _scanLines,
                resultFuture: _uploadFuture!,
                onFinished: _handleScanFinished,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLayer() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlitchText(text: _errorMessage!, fontSize: 14, color: AppColors.neonRed),
        ),
      );
    }

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        final controller = _controller;
        if (controller == null || !controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator(color: AppColors.toxicGreen));
        }
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? 1,
                height: controller.value.previewSize?.width ?? 1,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 8,
      left: 4,
      right: 20,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.toxicGreen),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(child: GlitchText(text: 'REALITY_GLITCH // SCAN', fontSize: 15)),
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.toxicGreen),
            tooltip: 'TARAMA_GEÇMİŞİ',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(border: Border.all(color: AppColors.neonRed)),
            child: const Text(
              'REC ●',
              style: TextStyle(color: AppColors.neonRed, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 36,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            _scanState == _ScanState.scanning ? 'TARANIYOR...' : 'HEDEFİ ORTALA VE TARA',
            style: TextStyle(
              color: AppColors.toxicGreen.withValues(alpha: 0.8),
              fontSize: 12,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          GlitchButton(onPressed: _capture, icon: Icons.center_focus_strong),
        ],
      ),
    );
  }
}
