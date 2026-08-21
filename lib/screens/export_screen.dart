import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/scene_asset.dart';
import '../models/target_engine.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glitch_action_button.dart';
import '../widgets/glitch_text.dart';

/// Lets the user pick a target 3D tool and transfers the scan's .glb there
/// (download + native share sheet) with a live progress readout. The file
/// itself never changes per engine — see [TargetEngine] — only the on-screen
/// guidance and the exported filename do.
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key, required this.asset});

  final SceneAsset asset;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  TargetEngine _engine = TargetEngine.godot;
  bool _isBusy = false;
  double? _progress;
  String? _error;
  File? _downloadedFile;

  Future<void> _startTransfer() async {
    final modelUrl = widget.asset.modelUrl;
    if (modelUrl == null || _isBusy) return;

    setState(() {
      _isBusy = true;
      _progress = 0;
      _error = null;
      _downloadedFile = null;
    });

    try {
      final dir = await getTemporaryDirectory();
      final fileName = 'realityglitch_${widget.asset.taskId}_${_engine.name}.glb';
      final file = await ApiService.downloadModel(
        modelUrl,
        savePath: '${dir.path}/$fileName',
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );

      if (!mounted) return;
      setState(() => _downloadedFile = file);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'RealityGlitch // ${_engine.label} için .glb sahne modeli',
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'AKTARIM BAŞARISIZ: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.toxicGreen),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(child: GlitchText(text: 'MODELİ AKTAR', fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'HEDEF PLATFORM SEÇ:',
                style: TextStyle(color: AppColors.toxicGreen, fontFamily: 'monospace', fontSize: 12, letterSpacing: 2),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: TargetEngine.values.map((engine) {
                  return _EngineChip(
                    label: engine.label,
                    selected: engine == _engine,
                    onTap: _isBusy ? null : () => setState(() => _engine = engine),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: AppColors.dimGreen)),
                child: Text(
                  '> ${_engine.importHint}',
                  style: TextStyle(
                    color: AppColors.toxicGreen.withValues(alpha: 0.8),
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              _buildProgress(),
              const SizedBox(height: 16),
              GlitchActionButton(
                label: _isBusy ? 'AKTARILIYOR...' : 'AKTAR / PAYLAŞ',
                icon: Icons.ios_share,
                onPressed: _startTransfer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final progress = _progress;
    String status;
    Color color = AppColors.toxicGreen;

    if (_error != null) {
      status = _error!;
      color = AppColors.neonRed;
    } else if (_downloadedFile != null && !_isBusy) {
      status = '✔ HAZIR: ${_downloadedFile!.uri.pathSegments.last}';
    } else if (_isBusy && progress != null) {
      status = '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}% AKTARILIYOR...';
    } else if (_isBusy) {
      status = 'AKTARILIYOR...';
    } else {
      status = 'AKTARIM İÇİN HAZIR.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 20,
          decoration: BoxDecoration(border: Border.all(color: AppColors.dimGreen)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (progress ?? 0).clamp(0.0, 1.0),
            child: Container(color: AppColors.toxicGreen.withValues(alpha: 0.35)),
          ),
        ),
        const SizedBox(height: 6),
        Text(status, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12, letterSpacing: 1)),
      ],
    );
  }
}

class _EngineChip extends StatelessWidget {
  const _EngineChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.toxicGreen : Colors.transparent,
          border: Border.all(color: AppColors.toxicGreen),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.black : AppColors.toxicGreen,
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
