import logging

from telegram import Update
from telegram.ext import Application, ContextTypes, MessageHandler, filters

from bot.config import get_settings
from bot.services.admin_reply import notify_admin_reply_sent, send_reply_to_user
from bot.services.forwarder import forward_to_admin, get_admin_chat_id, is_admin, register_admin
from bot.services.reply_store import get_user_chat_id
from bot.utils.rtl import rtl

logger = logging.getLogger(__name__)


async def _handle_admin_reply(
    update: Update, context: ContextTypes.DEFAULT_TYPE, settings
) -> bool:
    message = update.effective_message
    if not message or not message.reply_to_message:
        return False

    admin_chat_id = get_admin_chat_id(context, settings)
    if not admin_chat_id:
        return False

    user_chat_id = get_user_chat_id(admin_chat_id, message.reply_to_message.message_id)
    if not user_chat_id:
        await message.reply_text(
            rtl("کاربر این پیام پیدا نشد. فقط روی پیام‌های فوروارد شده Reply بزنید.")
        )
        return True

    try:
        await send_reply_to_user(context, message, user_chat_id)
        await notify_admin_reply_sent(message)
    except Exception:
        logger.exception("Failed to send admin reply to user %s", user_chat_id)
        await message.reply_text(rtl("خطا در ارسال پاسخ به کاربر."))
    return True


async def handle_incoming_message(
    update: Update, context: ContextTypes.DEFAULT_TYPE
) -> None:
    settings = get_settings()
    user = update.effective_user

    if is_admin(user, settings, update.effective_chat.id):
        register_admin(update, context)
        if await _handle_admin_reply(update, context, settings):
            return

        message = update.effective_message
        if message:
            text = message.text or ""
            if not text.startswith("/"):
                await message.reply_text(
                    rtl(
                        f"شما مدیر (@{settings.admin_username}) هستید.\n\n"
                        "• پیام کاربران به شما فوروارد می‌شود\n"
                        "• برای پاسخ: روی پیام کاربر Reply بزنید\n"
                        "• پاسخ شما به همان کاربر ارسال می‌شود"
                    )
                )
        return

    try:
        forwarded = await forward_to_admin(update, context, settings)
    except Exception:
        logger.exception("Failed to forward message to admin")
        message = update.effective_message
        if message:
            await message.reply_text(
                rtl("خطا در ارسال پیام به مدیر. لطفاً بعداً دوباره تلاش کنید.")
            )
        return

    if not forwarded:
        message = update.effective_message
        if message:
            await message.reply_text(
                rtl(
                    "پیام شما دریافت شد، اما فعلاً امکان ارسال به مدیر وجود ندارد.\n"
                    "لطفاً بعداً دوباره تلاش کنید."
                )
            )
        return

    message = update.effective_message
    if message:
        await message.reply_text(
            rtl("✅ پیام شما دریافت شد و به مدیر ارسال شد.")
        )


def register_message_handlers(application: Application) -> None:
    application.add_handler(MessageHandler(filters.ALL, handle_incoming_message))
