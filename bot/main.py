import asyncio
import logging
import sys

from telegram.ext import Application
from telegram.request import HTTPXRequest

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

    request = HTTPXRequest(
        connect_timeout=settings.connect_timeout,
        read_timeout=settings.read_timeout,
        write_timeout=settings.read_timeout,
        pool_timeout=settings.connect_timeout,
    )

    builder = (
        Application.builder()
        .token(settings.token)
        .request(request)
        .get_updates_request(request)
        .post_init(post_init)
    )

    if settings.proxy:
        logging.info("Using proxy: %s", settings.proxy)
        builder = builder.proxy(settings.proxy).get_updates_proxy(settings.proxy)

    application = builder.build()
    register_handlers(application)

    logging.info("ربات در حال اجراست...")
    if settings.proxy:
        logging.info("اتصال از طریق پروکسی: %s", settings.proxy)
    else:
        logging.info(
            "اگر خطای TimedOut گرفتید، VPN را روشن کنید یا TELEGRAM_PROXY را در .env تنظیم کنید."
        )
    application.run_polling(allowed_updates=["message", "edited_message"])


if __name__ == "__main__":
    main()
