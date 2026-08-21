import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/scene_asset.dart';
import '../utils/app_theme.dart';

typedef ScanFinishedCallback = void Function(SceneAsset? asset, Object? error);

/// Full-screen CLI-style overlay that types out [processingLines], then
/// genuinely waits on [resultFuture] before typing a final `[OK]`/`[HATA]`
/// line that reflects the real outcome — it never claims success while the
/// upload is still pending or has actually failed.
class TerminalScanOverlay extends StatefulWidget {
  const TerminalScanOverlay({
    super.key,
    required this.processingLines,
    required this.resultFuture,
    required this.onFinished,
  });

  final List<String> processingLines;
  final Future<SceneAsset> resultFuture;
  final ScanFinishedCallback onFinished;

  @override
  State<TerminalScanOverlay> createState() => _TerminalScanOverlayState();
}

class _TerminalScanOverlayState extends State<TerminalScanOverlay> {
  late final List<String> _lines = List.of(widget.processingLines);
  late final List<Color> _colors = List<Color>.filled(widget.processingLines.length, AppColors.toxicGreen, growable: true);
  final List<String> _rendered = [''];

  int _lineIndex = 0;
  int _charIndex = 0;
  Timer? _timer;

  bool _resultReady = false;
  bool _resultLineAppended = false;
  SceneAsset? _asset;
  Object? _error;

  DateTime? _holdStartedAt;
  int _waitSeconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 20), (_) => _tick());
    widget.resultFuture.then((asset) {
      _asset = asset;
    }).catchError((Object e) {
      _error = e;
    }).whenComplete(() {
      _resultReady = true;
    });
  }

  void _tick() {
    if (_lineIndex >= _lines.length) {
      _timer?.cancel();
      Future.delayed(const Duration(milliseconds: 600), () => widget.onFinished(_asset, _error));
      return;
    }

    final onLastProcessingLine = !_resultLineAppended && _lineIndex == _lines.length - 1;
    final line = _lines[_lineIndex];

    if (_charIndex < line.length) {
      setState(() {
        _charIndex++;
        _rendered[_lineIndex] = line.substring(0, _charIndex);
      });
      return;
    }

    // Fully typed the last processing line — hold here (cursor keeps
    // blinking) until the real network result comes back.
    if (onLastProcessingLine && !_resultReady) {
      _holdStartedAt ??= DateTime.now();
      final elapsed = DateTime.now().difference(_holdStartedAt!).inSeconds;
      if (elapsed != _waitSeconds) setState(() => _waitSeconds = elapsed);
      return;
    }

    if (onLastProcessingLine) {
      _resultLineAppended = true;
      final success = _error == null;
      _lines.add(success ? '[OK] TARAMA TAMAMLANDI — 3D MODEL HAZIR.' : '[HATA] TARAMA BAŞARISIZ.');
      _colors.add(success ? AppColors.toxicGreen : AppColors.neonRed);
    }

    setState(() {
      _lineIndex++;
      _charIndex = 0;
      if (_lineIndex < _lines.length) _rendered.add('');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black.withValues(alpha: 0.9),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _rendered.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '> ${_rendered[i]}',
                style: GoogleFonts.shareTechMono(
                  color: i < _colors.length ? _colors[i] : AppColors.toxicGreen,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),
          if (_holdStartedAt != null && !_resultLineAppended)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'SUNUCU YANITI BEKLENİYOR... (${_waitSeconds}sn)',
                style: GoogleFonts.shareTechMono(color: AppColors.toxicGreen.withValues(alpha: 0.55), fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          const _BlinkingCursor(),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(width: 10, height: 16, color: AppColors.toxicGreen),
    );
  }
}
