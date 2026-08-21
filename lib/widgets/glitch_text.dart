import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_theme.dart';

/// Text with a periodic chromatic-aberration "glitch" flicker — thin red/green
/// ghost layers jitter apart for a beat, then snap back.
class GlitchText extends StatefulWidget {
  const GlitchText({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.color = AppColors.toxicGreen,
    this.active = true,
  });

  final String text;
  final double fontSize;
  final Color color;
  final bool active;

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText> {
  final _random = Random();
  Timer? _timer;
  Offset _redOffset = Offset.zero;
  Offset _greenOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    if (widget.active) _scheduleGlitch();
  }

  void _scheduleGlitch() {
    _timer = Timer.periodic(const Duration(milliseconds: 2400), (_) async {
      if (!mounted) return;
      setState(() {
        _redOffset = Offset(_random.nextDouble() * 4 - 2, 0);
        _greenOffset = Offset(_random.nextDouble() * -4 + 2, 0);
      });
      await Future.delayed(const Duration(milliseconds: 110));
      if (!mounted) return;
      setState(() {
        _redOffset = Offset.zero;
        _greenOffset = Offset.zero;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  TextStyle _style(Color color) => GoogleFonts.shareTechMono(
        fontSize: widget.fontSize,
        color: color,
        letterSpacing: 2.5,
        fontWeight: FontWeight.w600,
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Transform.translate(
          offset: _redOffset,
          child: Text(widget.text, style: _style(AppColors.neonRed.withValues(alpha: 0.7))),
        ),
        Transform.translate(
          offset: _greenOffset,
          child: Text(widget.text, style: _style(AppColors.toxicGreen.withValues(alpha: 0.5))),
        ),
        Text(widget.text, style: _style(widget.color)),
      ],
    );
  }
}
