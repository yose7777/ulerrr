import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(const MonitoringApp());
}

class MonitoringApp extends StatelessWidget {
  const MonitoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoring Dashboard',
      theme: ThemeData.dark().copyWith(

        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.indigoAccent,
          thumbColor: Colors.indigo,
          overlayColor: Colors.indigo.withOpacity(0.2),
        ),
      ),
      home: const MonitoringHome(),
    );
  }
}

class MonitoringHome extends StatefulWidget {
  const MonitoringHome({super.key});

  @override
  State<MonitoringHome> createState() => _MonitoringHomeState();
}

class _MonitoringHomeState extends State<MonitoringHome> {
  final String serverIp = "http://192.168.111.101:8000"; // ganti sesuai IP server
  String status = "Loading...";
  int area = 0;

  Uint8List? currentFrame;
  Timer? dataTimer;
  DateTime lastUpdate = DateTime.now();

  double threshold = 128;
  double sepiLimit = 100000;
  double sedangLimit = 50000;
  double padatLimit = 0;

  StreamSubscription<List<int>>? videoSubscription;

  @override
  void initState() {
    super.initState();
    dataTimer = Timer.periodic(const Duration(seconds: 1), (t) => fetchData());
    startVideoStream();
  }

  @override
  void dispose() {
    dataTimer?.cancel();
    videoSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse("$serverIp/data/"));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          status = data["status"] ?? "Unknown";
          area = data["area"] ?? 0;
          sepiLimit = (data["limits"]["sepi"] ?? sepiLimit).toDouble();
          sedangLimit = (data["limits"]["sedang"] ?? sedangLimit).toDouble();
          padatLimit = (data["limits"]["padat"] ?? padatLimit).toDouble();
        });
      }
    } catch (_) {
      setState(() {
        status = "Tidak terhubung";
        area = 0;
      });
    }
  }

  Future<void> updateThreshold(double value) async {
    try {
      await http.post(
        Uri.parse("$serverIp/set_threshold/"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"threshold": value.toInt()}),
      );
    } catch (_) {}
  }

  Future<void> updateClassification() async {
    try {
      await http.post(
        Uri.parse("$serverIp/set_classification/"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "sepi": sepiLimit.toInt(),
          "sedang": sedangLimit.toInt(),
          "padat": padatLimit.toInt(),
        }),
      );
    } catch (_) {}
  }

  void startVideoStream() async {
    await videoSubscription?.cancel();
    try {
      final request = http.Request("GET", Uri.parse("$serverIp/video/"));
      final response = await request.send();
      List<int> buffer = [];
      videoSubscription = response.stream.listen((chunk) {
        buffer.addAll(chunk);
        for (int i = 0; i < buffer.length - 1; i++) {
          if (buffer[i] == 0xFF && buffer[i + 1] == 0xD8) {
            int start = i;
            for (int j = start + 2; j < buffer.length - 1; j++) {
              if (buffer[j] == 0xFF && buffer[j + 1] == 0xD9) {
                int end = j + 2;
                final frameBytes = buffer.sublist(start, end);
                buffer = buffer.sublist(end);
                if (DateTime.now().difference(lastUpdate).inMilliseconds > 100) {
                  setState(() => currentFrame = Uint8List.fromList(frameBytes));
                  lastUpdate = DateTime.now();
                }
                break;
              }
            }
            break;
          }
        }
      });
    } catch (_) {}
  }

  Color getStatusColor() {
    switch (status) {
      case "Sepi":
        return Colors.greenAccent;
      case "Sedang":
        return Colors.orangeAccent;
      case "Padat":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon() {
    switch (status) {
      case "Sepi":
        return Icons.check_circle_outline;
      case "Sedang":
        return Icons.warning_amber_rounded;
      case "Padat":
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  Widget buildSliderCard(String title, double value, double min, double max, Function(double) onChanged) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$title: ${value.toInt()}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              label: value.toInt().toString(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoring Dashboard"),
        centerTitle: true,
        backgroundColor: const Color(0xFF2A2A3C),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Status Card
          Card(
            child: ListTile(
              leading: Icon(getStatusIcon(), color: getStatusColor(), size: 40),
              title: Text("Status: $status",
                  style: TextStyle(color: getStatusColor(), fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text("Luas Area: $area", style: const TextStyle(color: Colors.white70)),
            ),
          ),

          // Sliders
          buildSliderCard("Threshold", threshold, 0, 255, (value) {
            setState(() => threshold = value);
            updateThreshold(value);
          }),
          buildSliderCard("Sepi Limit", sepiLimit, 0, 300000, (value) {
            setState(() => sepiLimit = value);
            updateClassification();
          }),
          buildSliderCard("Sedang Limit", sedangLimit, 0, 300000, (value) {
            setState(() => sedangLimit = value);
            updateClassification();
          }),
          buildSliderCard("Padat Limit", padatLimit, 0, 300000, (value) {
            setState(() => padatLimit = value);
            updateClassification();
          }),

          const SizedBox(height: 12),

          // Video Stream
          Expanded(
            child: Center(
              child: currentFrame != null
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.indigoAccent, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(currentFrame!, gaplessPlayback: true, fit: BoxFit.contain),
                      ),
                    )
                  : const Text("Menunggu video...", style: TextStyle(fontSize: 18, color: Colors.white70)),
            ),
          ),
        ],
      ),
    );
  }
}
