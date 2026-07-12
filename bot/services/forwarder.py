import logging

from telegram import Update
from telegram.ext import ContextTypes

from bot.config import Settings
from bot.utils.rtl import rtl

logger = logging.getLogger(__name__)


def is_admin(user, settings: Settings) -> bool:
    if not user or not user.username:
        return False
    return user.username.lower() == settings.admin_username.lower()


def get_admin_chat_id(context: ContextTypes.DEFAULT_TYPE, settings: Settings) -> int | None:
    if settings.admin_chat_id:
        return settings.admin_chat_id
    return context.bot_data.get("admin_chat_id")


def register_admin(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    chat_id = update.effective_chat.id
    context.bot_data["admin_chat_id"] = chat_id
    logger.info("Admin chat_id registered: %s", chat_id)


def _sender_info(update: Update) -> str:
    user = update.effective_user
    if not user:
        return rtl("📩 پیام جدید از کاربر ناشناس")

    username = f"@{user.username}" if user.username else "بدون username"
    return rtl(
        "📩 پیام جدید\n\n"
        f"• نام: {user.full_name}\n"
        f"• نام کاربری: {username}\n"
        f"• شناسه: {user.id}"
    )


async def forward_to_admin(
    update: Update,
    context: ContextTypes.DEFAULT_TYPE,
    settings: Settings,
) -> bool:
    admin_chat_id = get_admin_chat_id(context, settings)
    if not admin_chat_id:
        logger.warning("Admin chat_id is not set; message was not forwarded.")
        return False

    message = update.effective_message
    if not message:
        return False

    await context.bot.send_message(
        chat_id=admin_chat_id,
        text=_sender_info(update),
    )
    await message.forward(chat_id=admin_chat_id)
    return True
