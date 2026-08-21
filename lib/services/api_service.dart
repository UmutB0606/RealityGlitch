import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/scene_asset.dart';

/// Thrown when the RealityGlitch backend rejects a request or can't be reached.
class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to the RealityGlitch FastAPI backend, which turns a captured photo
/// into a game-engine-agnostic 3D scene package via Meshy's image-to-3D
/// pipeline. The backend returns a standard .glb download link + metadata,
/// so the same scan can be dropped into Godot, Unity or Unreal.
class ApiService {
  ApiService._();

  /// Dev machine's IP as seen by the phone. When the phone is on the same
  /// Wi-Fi router as this machine, that's the Wi-Fi adapter's LAN IP
  /// (192.168.1.x here). When the phone instead gets its internet via this
  /// laptop's Windows Mobile Hotspot, the phone is on the hotspot's own
  /// virtual-adapter subnet instead (192.168.137.1 here) — update this
  /// value whenever you switch between those two setups.
  static const String _devHost = '192.168.137.1';

  static String get _baseUrl => 'http://$_devHost:8000';

  static final Uri _healthUri = Uri.parse('$_baseUrl/health');
  static final Uri _generateSceneUri = Uri.parse('$_baseUrl/api/v1/generate-scene');

  /// Reads [imageFile] off disk and returns its Base64-encoded contents.
  static Future<String> encodeImageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  /// Quick reachability check so a down/unreachable backend fails in a few
  /// seconds with a clear message instead of silently hanging for minutes
  /// on the much longer [uploadSceneCapture] timeout.
  static Future<bool> isBackendReachable() async {
    try {
      final response = await http.get(_healthUri).timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Uploads a captured photo to the backend and waits for the resulting
  /// engine-agnostic 3D scene asset (a .glb URL + metadata).
  static Future<SceneAsset> uploadSceneCapture(File imageFile) async {
    if (!await isBackendReachable()) {
      throw ApiException('SUNUCUYA ULAŞILAMIYOR ($_baseUrl). BACKEND ÇALIŞIYOR MU?');
    }

    final base64Image = await encodeImageToBase64(imageFile);

    http.Response response;
    try {
      response = await http
          .post(
            _generateSceneUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image_base64': base64Image, 'mime_type': 'image/png'}),
          )
          .timeout(const Duration(seconds: 320));
    } catch (e) {
      throw ApiException('SUNUCUYA ULAŞILAMADI: $e');
    }

    if (response.statusCode != 200) {
      throw ApiException('SUNUCU HATASI (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SceneAsset.fromJson(data);
  }

  /// Streams [modelUrl] to [savePath], reporting real download progress
  /// (0.0-1.0) via [onProgress] whenever the server sends a Content-Length.
  /// If it doesn't, [onProgress] is simply never called rather than faking a
  /// number — callers should show an indeterminate state in that case.
  static Future<File> downloadModel(
    String modelUrl, {
    required String savePath,
    void Function(double progress)? onProgress,
  }) async {
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(modelUrl)));
      if (response.statusCode != 200) {
        throw ApiException('İNDİRME BAŞARISIZ (${response.statusCode})');
      }

      final total = response.contentLength;
      final bytes = <int>[];
      var received = 0;

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total != null && total > 0) {
          onProgress?.call(received / total);
        }
      }

      final file = File(savePath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('İNDİRME BAŞARISIZ: $e');
    } finally {
      client.close();
    }
  }
}
