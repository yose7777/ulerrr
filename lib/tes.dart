import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MonitoringApp());
}

class MonitoringApp extends StatelessWidget {
  const MonitoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoring App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MonitoringPage(),
    );
  }
}

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  int threshold = 127;
  int width = 640;
  int height = 480;

  String status = "Memuat...";
  int area = 0;

  final String baseUrl = "http://192.168.1.10:8000"; // ganti IP server Django

  String get videoUrl =>
      "$baseUrl/video_feed?threshold=$threshold&width=$width&height=$height";

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(
          "$baseUrl/data_feed?threshold=$threshold&width=$width&height=$height"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          status = data["status"];
          area = data["area"];
        });
      }
    } catch (e) {
      setState(() {
        status = "Gagal mengambil data";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void updateSetting({int? newThreshold, int? newWidth, int? newHeight}) {
    setState(() {
      if (newThreshold != null) threshold = newThreshold;
      if (newWidth != null) width = newWidth;
      if (newHeight != null) height = newHeight;
    });
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monitoring App")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Image.network(
                videoUrl,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Text("Gagal menampilkan video")),
              ),
            ),
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("STATUS: $status",
                      style: const TextStyle(color: Colors.orange, fontSize: 20)),
                  Text("Luas Area: $area",
                      style: const TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
            const Divider(),

            // Slider Threshold
            Text("Threshold: $threshold"),
            Slider(
              value: threshold.toDouble(),
              min: 0,
              max: 255,
              divisions: 255,
              label: "$threshold",
              onChanged: (val) => updateSetting(newThreshold: val.toInt()),
            ),

            // Tombol untuk mengatur threshold
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (threshold > 0) {
                      updateSetting(newThreshold: threshold - 5);
                    }
                  },
                  child: const Text("-"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    if (threshold < 255) {
                      updateSetting(newThreshold: threshold + 5);
                    }
                  },
                  child: const Text("+"),
                ),
              ],
            ),

            const SizedBox(height: 2000),

            // Slider Width
            Text("Lebar Kamera: $width"),
            Slider(
              value: width.toDouble(),
              min: 320,
              max: 1280,
              divisions: 10,
              label: "$width",
              onChanged: (val) => updateSetting(newWidth: val.toInt()),
            ),

            // Slider Height
            Text("Tinggi Kamera: $height"),
            Slider(
              value: height.toDouble(),
              min: 240,
              max: 720,
              divisions: 10,
              label: "$height",
              onChanged: (val) => updateSetting(newHeight: val.toInt()),
            ),
          ],
        ),
      ),
    );
  }
}
