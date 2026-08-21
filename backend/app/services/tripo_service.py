import base64
import tempfile
from pathlib import Path
from typing import Any

from tripo3d import TaskStatus, TripoClient

from app.config import settings

# Leaves headroom under the Flutter client's 320s request timeout.
TASK_TIMEOUT_SECONDS = 280.0


class TripoAPIError(Exception):
    """Raised when Tripo rejects a request or a generation task fails/times out."""


async def generate_model_from_base64(image_base64: str, mime_type: str = "image/png") -> dict[str, Any]:
    """Submits a Base64 photo to Tripo's image-to-3D pipeline and waits for the
    result. Returns a plain dict with task_id, status, model_url and
    thumbnail_url — the SDK's TripoClient does the upload + polling for us.
    """
    suffix = ".png" if "png" in mime_type else ".jpg"
    image_bytes = base64.b64decode(image_base64)

    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(image_bytes)
        tmp_path = Path(tmp.name)

    try:
        async with TripoClient(api_key=settings.tripo_api_key) as client:
            task_id = await client.image_to_model(image=str(tmp_path))
            task = await client.wait_for_task(task_id, timeout=TASK_TIMEOUT_SECONDS)

            if task.status != TaskStatus.SUCCESS:
                raise TripoAPIError(f"Tripo task {task_id} did not succeed (status={task.status})")

            model_url = task.output.pbr_model or task.output.model or task.output.base_model
            if not model_url:
                raise TripoAPIError(f"Tripo task {task_id} succeeded but returned no model URL")

            status = task.status.value if hasattr(task.status, "value") else str(task.status)
            return {
                "task_id": task_id,
                "status": status,
                "model_url": model_url,
                "thumbnail_url": task.output.rendered_image,
            }
    except TripoAPIError:
        raise
    except Exception as exc:
        raise TripoAPIError(f"Tripo request failed: {exc}") from exc
    finally:
        tmp_path.unlink(missing_ok=True)
