import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reality_glitch/main.dart';

void main() {
  testWidgets('RealityGlitch app boots into the home menu', (WidgetTester tester) async {
    await tester.pumpWidget(const RealityGlitchApp());
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    // GlitchText/GlitchActionButton each layer their label 3x (red/green ghosts + base) for the flicker effect.
    expect(find.text('REALITY_GLITCH'), findsWidgets);
    expect(find.text('TARAMAYA BAŞLA'), findsWidgets);
    expect(find.text('TARAMA_GEÇMİŞİ'), findsWidgets);
  });
}
