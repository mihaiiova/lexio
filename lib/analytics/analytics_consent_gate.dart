import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import 'analytics_consent_screen.dart';
import 'analytics_service.dart';

class AnalyticsConsentGate extends StatefulWidget {
  const AnalyticsConsentGate({super.key});

  @override
  State<AnalyticsConsentGate> createState() => _AnalyticsConsentGateState();
}

class _AnalyticsConsentGateState extends State<AnalyticsConsentGate> {
  @override
  Widget build(BuildContext context) {
    if (AnalyticsService.consent == null) {
      return AnalyticsConsentScreen(
        onDecided: () => setState(() {}),
      );
    }
    return const HomeScreen();
  }
}
