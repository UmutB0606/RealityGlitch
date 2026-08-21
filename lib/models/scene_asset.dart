/// Mirrors the backend's `SceneAssetResponse` — an engine-agnostic 3D scene
/// result (a .glb download link + metadata) produced by the RealityGlitch API.
class SceneAsset {
  const SceneAsset({
    required this.taskId,
    required this.status,
    required this.format,
    this.modelUrl,
    this.thumbnailUrl,
    this.metadata = const {},
  });

  factory SceneAsset.fromJson(Map<String, dynamic> json) {
    return SceneAsset(
      taskId: json['task_id'] as String,
      status: json['status'] as String,
      format: json['format'] as String? ?? 'glb',
      modelUrl: json['model_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  final String taskId;
  final String status;
  final String format;
  final String? modelUrl;
  final String? thumbnailUrl;
  final Map<String, dynamic> metadata;
}
