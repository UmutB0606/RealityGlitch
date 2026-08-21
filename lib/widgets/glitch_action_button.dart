import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';

/// Rectangular labeled button that splits into red/green chromatic-aberration
/// ghosts on tap — the text-label counterpart to [GlitchButton]'s capture ring.
class GlitchActionButton extends StatefulWidget {
  const GlitchActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.ios_share,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  State<GlitchActionButton> createState() => _GlitchActionButtonState();
}

class _GlitchActionButtonState extends State<GlitchActionButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  void _handleTap() {
    _controller.forward(from: 0).then((_) => _controller.reverse());
    widget.onPressed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _content(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(border: Border.all(color: color, width: 1.4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            widget.label,
            style: GoogleFonts.shareTechMono(
              color: color,
              fontSize: 14,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final jitter = _controller.value * 5;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(-jitter, 0),
                child: _content(AppColors.neonRed.withValues(alpha: 0.55)),
              ),
              Transform.translate(
                offset: Offset(jitter, 0),
                child: _content(AppColors.toxicGreen.withValues(alpha: 0.55)),
              ),
              _content(AppColors.toxicGreen),
            ],
          );
        },
      ),
    );
  }
}
