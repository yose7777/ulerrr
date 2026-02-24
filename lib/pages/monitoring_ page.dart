import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/monitoring_service.dart';

class MonitoringHome extends StatefulWidget {
  const MonitoringHome({super.key});

  @override
  State<MonitoringHome> createState() => _MonitoringHomeState();
}

class _MonitoringHomeState extends State<MonitoringHome> {

  final service = MonitoringService("http://192.168.111.102:8000");

  int selectedCam = 1;

  String status = "Loading...";
  int area = 0;

  Uint8List? currentFrame;
  Timer? dataTimer;
  StreamSubscription? videoSub;

  double threshold = 128;
  double sepiLimit = 100000;
  double sedangLimit = 50000;
  double padatLimit = 0;

  // ================= SETTINGS PER CAMERA =================

  Future<void> loadSettings(int cam) async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      threshold = prefs.getDouble("threshold_cam$cam") ?? 128;
      sepiLimit = prefs.getDouble("sepi_cam$cam") ?? 100000;
      sedangLimit = prefs.getDouble("sedang_cam$cam") ?? 50000;
      padatLimit = prefs.getDouble("padat_cam$cam") ?? 0;
    });

    await service.updateThreshold(cam, threshold);
    await service.updateClassification(
        cam, sepiLimit, sedangLimit, padatLimit);
  }

  Future<void> saveSettings(int cam) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble("threshold_cam$cam", threshold);
    await prefs.setDouble("sepi_cam$cam", sepiLimit);
    await prefs.setDouble("sedang_cam$cam", sedangLimit);
    await prefs.setDouble("padat_cam$cam", padatLimit);
  }

  @override
  void initState() {
    super.initState();
    loadSettings(selectedCam);
    startDataPolling();
    startVideo();
  }

  @override
  void dispose() {
    dataTimer?.cancel();
    videoSub?.cancel();
    super.dispose();
  }

  // ================= DATA =================

  void startDataPolling() {

    dataTimer = Timer.periodic(const Duration(seconds: 2), (_) async {

      final data = await service.fetchData();
      if (data == null) return;

      final cams = data["cameras"];
      if (cams == null) return;

      final camData = cams[selectedCam - 1];

      setState(() {
        status = camData["status"];
        area = camData["area"];
      });
    });
  }

  void startVideo() async {

    final stream = await service.startVideoStream();
    if (stream == null) return;

    videoSub = service.parseMjpeg(stream).listen((frame) {
      setState(() => currentFrame = frame);
    });
  }

  // ================= STATUS =================

  Color getStatusColor() {
    switch (status) {
      case "Sepi":
        return Colors.green;
      case "Sedang":
        return Colors.orange;
      case "Padat":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ================= CAMERA SETTINGS MODAL =================

  void showCameraSettings(int cam) {

    loadSettings(cam);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {

        return StatefulBuilder(
          builder: (context, setModalState) {

            Widget slider(String title, double value, double max,
                Function(double) onChanged) {

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "$title : ${value.toInt()}",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),

                  Slider(
                    value: value,
                    max: max,
                    onChanged: onChanged,
                  ),

                  const SizedBox(height: 10),
                ],
              );
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [

                    Container(
                      width: 60,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    Text(
                      "Camera $cam Settings",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    slider("Threshold", threshold, 255, (v) async {
                      setModalState(() => threshold = v);
                      await saveSettings(cam);
                      service.updateThreshold(cam, v);
                    }),

                    slider("Sepi Limit", sepiLimit, 300000, (v) async {
                      setModalState(() => sepiLimit = v);
                      await saveSettings(cam);
                      service.updateClassification(
                          cam, sepiLimit, sedangLimit, padatLimit);
                    }),

                    slider("Sedang Limit", sedangLimit, 300000, (v) async {
                      setModalState(() => sedangLimit = v);
                      await saveSettings(cam);
                      service.updateClassification(
                          cam, sepiLimit, sedangLimit, padatLimit);
                    }),

                    slider("Padat Limit", padatLimit, 300000, (v) async {
                      setModalState(() => padatLimit = v);
                      await saveSettings(cam);
                      service.updateClassification(
                          cam, sepiLimit, sedangLimit, padatLimit);
                    }),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= CAMERA CARD =================

  Widget cameraCard(int camNumber) {

    bool selected = selectedCam == camNumber;

    return GestureDetector(
      onTap: () async {

        setState(() => selectedCam = camNumber);

        await loadSettings(camNumber);

        showCameraSettings(camNumber);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [

              Positioned.fill(
                child: currentFrame != null
                    ? Image.memory(
                        currentFrame!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                    : Container(color: Colors.black12),
              ),

              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "CAM $camNumber",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),

      appBar: AppBar(
        title: const Text("AI Monitoring Dashboard"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.3,
              children: List.generate(4, (i) => cameraCard(i + 1)),
            ),

            const SizedBox(height: 16),

            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    getStatusColor().withOpacity(0.8),
                    getStatusColor()
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: getStatusColor().withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(
                children: [

                  const Icon(Icons.analytics,
                      color: Colors.white, size: 40),

                  const SizedBox(width: 14),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Status : $status",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),

                      Text(
                        "Area : $area",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}