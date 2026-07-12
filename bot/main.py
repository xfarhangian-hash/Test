import asyncio
import logging
import sys

from telegram.ext import Application

from bot.config import get_settings
from bot.handlers import register_handlers

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logging.getLogger("httpx").setLevel(logging.WARNING)


def _ensure_event_loop() -> None:
    """Python 3.14+ on Windows no longer auto-creates an event loop."""
    try:
        asyncio.get_event_loop()
    except RuntimeError:
        asyncio.set_event_loop(asyncio.new_event_loop())


def main() -> None:
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    _ensure_event_loop()
    settings = get_settings()

    async def post_init(application: Application) -> None:
        if settings.admin_chat_id:
            application.bot_data["admin_chat_id"] = settings.admin_chat_id

    application = (
        Application.builder()
        .token(settings.token)
        .post_init(post_init)
        .build()
    )
    register_handlers(application)

    logging.info("ربات در حال اجراست...")
    application.run_polling(allowed_updates=["message", "edited_message"])


if __name__ == "__main__":
    main()
