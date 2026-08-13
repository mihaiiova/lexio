import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../analytics/analytics_consent_gate.dart';
import '../design/theme.dart';

class LexioApp extends StatelessWidget {
  const LexioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slove',
      debugShowCheckedModeBanner: false,
      theme: LexioTheme.light,
      locale: const Locale('ro'),
      supportedLocales: const [Locale('ro')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AnalyticsConsentGate(),
    );
  }
}
