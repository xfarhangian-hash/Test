from datetime import datetime
from zoneinfo import ZoneInfo

from telegram import Update
from telegram.ext import Application, CallbackQueryHandler, ContextTypes

from bot.handlers.commands import ABOUT_TEXT, HELP_TEXT


async def handle_callback(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    query = update.callback_query
    await query.answer()

    data = query.data
    user = query.from_user

    if data == "time":
        now = datetime.now(ZoneInfo("Asia/Tehran"))
        text = f"🕐 زمان فعلی تهران:\n`{now.strftime('%Y/%m/%d — %H:%M:%S')}`"
        await query.edit_message_text(text, parse_mode="Markdown")

    elif data == "profile":
        username = f"@{user.username}" if user.username else "—"
        text = (
            "👤 **پروفایل شما**\n\n"
            f"• نام: {user.full_name}\n"
            f"• نام کاربری: {username}\n"
            f"• شناسه: `{user.id}`"
        )
        await query.edit_message_text(text, parse_mode="Markdown")

    elif data == "help":
        await query.edit_message_text(HELP_TEXT, parse_mode="Markdown")

    elif data == "about":
        await query.edit_message_text(ABOUT_TEXT, parse_mode="Markdown")


def register_callback_handlers(application: Application) -> None:
    application.add_handler(CallbackQueryHandler(handle_callback))
