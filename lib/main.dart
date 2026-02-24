import 'package:flutter/material.dart';
import 'pages/monitoring_ page.dart';

void main() {
  runApp(const MonitoringApp());
}

class MonitoringApp extends StatelessWidget {
  const MonitoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoring Dashboard',
      theme: ThemeData.dark(),
      home: const MonitoringHome(),
    );
  }
}
