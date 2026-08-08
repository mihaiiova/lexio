import 'package:flutter/material.dart';

import 'analytics/analytics_service.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AnalyticsService.initialize();
  runApp(const LexioApp());
}
