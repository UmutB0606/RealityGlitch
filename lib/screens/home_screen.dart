import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../widgets/glitch_action_button.dart';
import '../widgets/glitch_text.dart';
import 'history_screen.dart';
import 'scanner_screen.dart';

/// Landing screen — the entry point users see before jumping into the
/// camera. Offers the two things the app can do: start a new scan, or
/// revisit past ones.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const GlitchText(text: 'REALITY_GLITCH', fontSize: 32),
              const SizedBox(height: 10),
              Text(
                'GERÇEKLİĞİ TARA // SAHNEYE DÖNÜŞTÜR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.toxicGreen.withValues(alpha: 0.55),
                  fontFamily: 'monospace',
                  fontSize: 12,
                  letterSpacing: 3,
                ),
              ),
              const Spacer(flex: 4),
              GlitchActionButton(
                label: 'TARAMAYA BAŞLA',
                icon: Icons.center_focus_strong,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScannerScreen()),
                ),
              ),
              const SizedBox(height: 18),
              GlitchActionButton(
                label: 'TARAMA_GEÇMİŞİ',
                icon: Icons.history,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
              const Spacer(flex: 5),
              const Text(
                'v0.1.0 // ENGINE-AGNOSTIC 3D CAPTURE',
                style: TextStyle(
                  color: AppColors.dimGreen,
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
