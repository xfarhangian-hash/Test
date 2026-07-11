import os
from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv()


@dataclass(frozen=True)
class Settings:
    token: str
    bot_name: str = "ربات من"


def get_settings() -> Settings:
    token = os.getenv("TELEGRAM_BOT_TOKEN", "").strip()
    if not token:
        raise RuntimeError(
            "توکن ربات تنظیم نشده است. "
            "متغیر TELEGRAM_BOT_TOKEN را در فایل .env قرار دهید."
        )
    return Settings(token=token)
