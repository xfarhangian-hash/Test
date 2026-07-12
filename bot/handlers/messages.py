import logging

from telegram import Update
from telegram.ext import Application, ContextTypes, MessageHandler, filters

from bot.config import get_settings
from bot.services.forwarder import forward_to_admin, is_admin, register_admin
from bot.utils.rtl import rtl

logger = logging.getLogger(__name__)


async def handle_incoming_message(
    update: Update, context: ContextTypes.DEFAULT_TYPE
) -> None:
    settings = get_settings()
    user = update.effective_user

    if is_admin(user, settings):
        register_admin(update, context)
        message = update.effective_message
        if message:
            text = message.text or ""
            if not text.startswith("/"):
                await message.reply_text(
                    rtl(
                        f"شما مدیر (@{settings.admin_username}) هستید.\n"
                        "پیام‌های شما فوروارد نمی‌شوند.\n\n"
                        "برای تست: با یک اکانت دیگر (نه این حساب) به ربات پیام بدهید."
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
