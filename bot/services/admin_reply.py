import logging

from telegram import Message
from telegram.ext import ContextTypes

from bot.utils.rtl import rtl

logger = logging.getLogger(__name__)


async def send_reply_to_user(
    context: ContextTypes.DEFAULT_TYPE,
    admin_message: Message,
    user_chat_id: int,
) -> None:
    await context.bot.copy_message(
        chat_id=user_chat_id,
        from_chat_id=admin_message.chat_id,
        message_id=admin_message.message_id,
    )
    logger.info("Admin reply copied to user chat_id=%s", user_chat_id)


async def notify_admin_reply_sent(admin_message: Message) -> None:
    await admin_message.reply_text(rtl("✅ پاسخ شما به کاربر ارسال شد."))
