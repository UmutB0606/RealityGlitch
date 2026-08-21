from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.schemas import GenerateSceneRequest, SceneAssetResponse
from app.services.tripo_service import TripoAPIError, generate_model_from_base64

app = FastAPI(
    title="RealityGlitch Backend",
    description=(
        "Turns photos captured by the RealityGlitch mobile app into "
        "engine-agnostic 3D scene assets via Tripo3D's image-to-3D API."
    ),
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health_check() -> dict[str, str]:
    return {"status": "ok"}


def _detect_format(model_url: str) -> str:
    filename = model_url.split("?", 1)[0].rsplit("/", 1)[-1]
    return filename.rsplit(".", 1)[-1].lower() if "." in filename else "glb"


@app.post("/api/v1/generate-scene", response_model=SceneAssetResponse)
async def generate_scene(request: GenerateSceneRequest) -> SceneAssetResponse:
    """
    Accepts a Base64 photo, runs it through Tripo3D's image-to-3D pipeline,
    and returns a universal 3D model download link plus metadata.

    The response is intentionally engine-agnostic: it is never converted into
    a Unity/Unreal/Godot-specific asset. Any tool that reads glTF can import
    the returned model_url directly.
    """
    try:
        result = await generate_model_from_base64(request.image_base64, request.mime_type)
    except TripoAPIError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    model_url = result["model_url"]

    return SceneAssetResponse(
        task_id=result["task_id"],
        status=result["status"],
        format=_detect_format(model_url),
        model_url=model_url,
        thumbnail_url=result.get("thumbnail_url"),
        metadata={
            "engine_agnostic": True,
            "compatible_with": ["Godot", "Unity", "Unreal Engine", "Blender"],
            "source": "tripo3d",
        },
    )
