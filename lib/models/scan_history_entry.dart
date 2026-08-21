import 'scene_asset.dart';

/// A locally persisted record of a past successful scan, so the user can
/// come back to a generated model after leaving the result screen.
class ScanHistoryEntry {
  const ScanHistoryEntry({
    required this.taskId,
    required this.modelUrl,
    required this.createdAt,
    this.thumbnailUrl,
    this.status = 'SUCCEEDED',
  });

  factory ScanHistoryEntry.fromAsset(SceneAsset asset) {
    assert(asset.modelUrl != null, 'Only successful scans (with a model_url) can be saved to history');
    return ScanHistoryEntry(
      taskId: asset.taskId,
      modelUrl: asset.modelUrl!,
      thumbnailUrl: asset.thumbnailUrl,
      status: asset.status,
      createdAt: DateTime.now(),
    );
  }

  factory ScanHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ScanHistoryEntry(
      taskId: json['task_id'] as String,
      modelUrl: json['model_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String? ?? 'SUCCEEDED',
    );
  }

  final String taskId;
  final String modelUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final String status;

  SceneAsset toSceneAsset() {
    return SceneAsset(taskId: taskId, status: status, format: 'glb', modelUrl: modelUrl, thumbnailUrl: thumbnailUrl);
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'model_url': modelUrl,
      'thumbnail_url': thumbnailUrl,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }
}
