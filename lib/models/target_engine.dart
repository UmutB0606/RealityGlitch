/// The 3D tools a generated .glb can be handed off to. The backend never
/// produces engine-specific files (see [ApiService]) — this only changes the
/// on-screen import instructions and the exported file's name.
enum TargetEngine { godot, unity, unreal, blender, generic }

extension TargetEngineInfo on TargetEngine {
  String get label => switch (this) {
        TargetEngine.godot => 'GODOT',
        TargetEngine.unity => 'UNITY',
        TargetEngine.unreal => 'UNREAL ENGINE',
        TargetEngine.blender => 'BLENDER',
        TargetEngine.generic => 'DİĞER (.glb)',
      };

  String get importHint => switch (this) {
        TargetEngine.godot =>
          'GODOT: .glb dosyasını proje klasörüne kopyala; FileSystem panelinden sahneye sürükle-bırak ile ekle.',
        TargetEngine.unity =>
          'UNITY: .glb dosyasını Assets klasörüne sürükle (glTFast veya UnityGLTF eklentisi gerekir).',
        TargetEngine.unreal =>
          'UNREAL ENGINE: dosyayı Content Browser\'a sürükle; Interchange içe aktarma otomatik başlar.',
        TargetEngine.blender => 'BLENDER: File > Import > glTF 2.0 (.glb/.gltf) ile aç.',
        TargetEngine.generic => 'Standart glTF Binary (.glb) — glTF destekleyen her 3D yazılımına aktarılabilir.',
      };
}
