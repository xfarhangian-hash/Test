import os
from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv()


@dataclass(frozen=True)
class Settings:
    token: str
    admin_username: str
    admin_chat_id: int | None = None
    proxy: str | None = None
    connect_timeout: float = 30.0
    read_timeout: float = 30.0
    bot_name: str = "ربات من"


def get_settings() -> Settings:
    token = os.getenv("TELEGRAM_BOT_TOKEN", "").strip()
    if not token:
        raise RuntimeError(
            "توکن ربات تنظیم نشده است. "
            "متغیر TELEGRAM_BOT_TOKEN را در فایل .env قرار دهید."
        )

    admin_username = os.getenv("ADMIN_USERNAME", "MohsenFarhangian").strip().lstrip("@")
    admin_chat_id_raw = os.getenv("ADMIN_CHAT_ID", "1755704405").strip()
    admin_chat_id = int(admin_chat_id_raw) if admin_chat_id_raw else None
    proxy = os.getenv("TELEGRAM_PROXY", "").strip() or None

    return Settings(
        token=token,
        admin_username=admin_username,
        admin_chat_id=admin_chat_id,
        proxy=proxy,
    )
