import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class MonitoringService {

  final String baseUrl;

  MonitoringService(this.baseUrl);

  Future<Map<String, dynamic>?> fetchData() async {

    final res = await http.get(
      Uri.parse("$baseUrl/data_feed/"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return null;
  }

  Future<void> updateThreshold(int cam, double value) async {

    await http.post(
      Uri.parse("$baseUrl/set_threshold/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "cam": cam,
        "threshold": value.toInt(),
      }),
    );
  }

  Future<void> updateClassification(
      int cam,
      double sepi,
      double sedang,
      double padat) async {

    await http.post(
      Uri.parse("$baseUrl/set_classification/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "cam": cam,
        "sepi": sepi.toInt(),
        "sedang": sedang.toInt(),
        "padat": padat.toInt(),
      }),
    );
  }

  Future<Stream<List<int>>?> startVideoStream() async {

    final request =
        http.Request("GET", Uri.parse("$baseUrl/video_feed/"));

    final response = await request.send();

    return response.stream;
  }

  Stream<Uint8List> parseMjpeg(Stream<List<int>> stream) async* {

    List<int> buffer = [];

    await for (var chunk in stream) {

      buffer.addAll(chunk);

      while (true) {

        int start = _indexOf(buffer, [0xFF, 0xD8]);
        int end = _indexOf(buffer, [0xFF, 0xD9]);

        if (start != -1 && end != -1 && end > start) {

          Uint8List frame =
              Uint8List.fromList(buffer.sublist(start, end + 2));

          yield frame;

          buffer = buffer.sublist(end + 2);

        } else {
          break;
        }
      }
    }
  }

  int _indexOf(List<int> data, List<int> pattern) {
    for (int i = 0; i < data.length - pattern.length; i++) {
      bool found = true;
      for (int j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }
}