import logging

from telegram.ext import Application

from bot.config import get_settings
from bot.handlers import register_handlers

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logging.getLogger("httpx").setLevel(logging.WARNING)


def main() -> None:
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
