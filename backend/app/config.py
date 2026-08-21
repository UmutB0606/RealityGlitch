import os
from functools import lru_cache

from dotenv import load_dotenv

load_dotenv()


class Settings:
    tripo_api_key: str = os.getenv("TRIPO_API_KEY", "YOUR_TRIPO_API_KEY")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
