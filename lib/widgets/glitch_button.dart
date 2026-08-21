import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Circular capture button that splits into red/green ghost rings on tap,
/// echoing the app's chromatic-aberration glitch motif.
class GlitchButton extends StatefulWidget {
  const GlitchButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.center_focus_strong,
    this.size = 76,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final double size;

  @override
  State<GlitchButton> createState() => _GlitchButtonState();
}

class _GlitchButtonState extends State<GlitchButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
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

  Widget _ring(Color color, {bool filled = false}) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        color: filled ? AppColors.black : Colors.transparent,
      ),
      alignment: Alignment.center,
      child: filled ? Icon(widget.icon, color: AppColors.toxicGreen, size: widget.size * 0.4) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final jitter = _controller.value * 6;
          return SizedBox(
            width: widget.size + 8,
            height: widget.size + 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(-jitter, 0),
                  child: _ring(AppColors.neonRed.withValues(alpha: 0.6)),
                ),
                Transform.translate(
                  offset: Offset(jitter, 0),
                  child: _ring(AppColors.toxicGreen.withValues(alpha: 0.6)),
                ),
                _ring(AppColors.toxicGreen, filled: true),
              ],
            ),
          );
        },
      ),
    );
  }
}
