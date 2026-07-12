import logging

from telegram import Update
from telegram.ext import ContextTypes

from bot.services.reply_store import link_message
from bot.config import Settings
from bot.utils.rtl import rtl

logger = logging.getLogger(__name__)


def is_admin(user, settings: Settings, chat_id: int | None = None) -> bool:
    if chat_id and settings.admin_chat_id and chat_id == settings.admin_chat_id:
        return True
    if not user or not user.username:
        return False
    return user.username.lower() == settings.admin_username.lower()


def get_admin_chat_id(context: ContextTypes.DEFAULT_TYPE, settings: Settings) -> int | None:
    if settings.admin_chat_id:
        return settings.admin_chat_id
    return context.bot_data.get("admin_chat_id")


def register_admin(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    chat_id = update.effective_chat.id
    if context.bot_data.get("admin_chat_id") == chat_id:
        return
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
        f"• شناسه: {user.id}\n\n"
        "↩️ برای پاسخ: Reply روی این پیام یا پیام فوروارد شده بزنید."
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

    user_chat_id = update.effective_chat.id

    info_msg = await context.bot.send_message(
        chat_id=admin_chat_id,
        text=_sender_info(update),
    )
    forwarded_msg = await message.forward(chat_id=admin_chat_id)

    link_message(admin_chat_id, info_msg.message_id, user_chat_id)
    link_message(admin_chat_id, forwarded_msg.message_id, user_chat_id)
    user = update.effective_user
    username = f"@{user.username}" if user and user.username else str(user.id if user else "?")
    logger.info("Message forwarded to admin from %s", username)
    return True
