from typing import Any, Optional

from pydantic import BaseModel, Field


class GenerateSceneRequest(BaseModel):
    image_base64: str = Field(..., description="Base64-encoded photo captured by the RealityGlitch mobile app")
    mime_type: str = Field(default="image/png", description="MIME type of the source image")


class SceneAssetResponse(BaseModel):
    task_id: str
    status: str
    format: str = "glb"
    model_url: Optional[str] = Field(default=None, description="Direct download link to the .glb model")
    thumbnail_url: Optional[str] = None
    metadata: dict[str, Any] = Field(default_factory=dict)
