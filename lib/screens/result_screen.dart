import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../models/scene_asset.dart';
import '../utils/app_theme.dart';
import '../widgets/glitch_action_button.dart';
import '../widgets/glitch_text.dart';
import 'export_screen.dart';

/// Shows the engine-agnostic 3D scene asset returned by the backend: an
/// interactive (rotate/zoom) .glb viewer plus an entry point into the
/// [ExportScreen] transfer flow.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.asset});

  final SceneAsset asset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildViewer(),
            _buildTopBar(context),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildViewer() {
    final modelUrl = asset.modelUrl;
    if (modelUrl == null) {
      return const Center(
        child: GlitchText(text: 'MODEL_URL BULUNAMADI', fontSize: 14, color: AppColors.neonRed),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 68, 20, 116),
      decoration: BoxDecoration(border: Border.all(color: AppColors.dimGreen, width: 1)),
      child: ClipRect(
        child: ModelViewer(
          key: ValueKey(modelUrl),
          src: modelUrl,
          alt: 'RealityGlitch generated 3D scene',
          backgroundColor: Colors.transparent,
          autoRotate: true,
          cameraControls: true,
          disableZoom: false,
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
          const Expanded(child: GlitchText(text: 'RENDER_SONUCU // 3D_MODEL', fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Center(
        child: GlitchActionButton(
          label: 'MODELİ AKTAR',
          icon: Icons.send_outlined,
          onPressed: asset.modelUrl == null
              ? () {}
              : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExportScreen(asset: asset))),
        ),
      ),
    );
  }
}
