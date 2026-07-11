from telegram import Update
from telegram.ext import Application, ContextTypes, MessageHandler, filters


async def echo_text(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    text = update.message.text
    await update.message.reply_text(
        f"پیام شما:\n\n{text}\n\n"
        "برای دیدن دستورات از /help استفاده کنید."
    )


async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    photo = update.message.photo[-1]
    await update.message.reply_text(
        f"📷 عکس دریافت شد!\n"
        f"ابعاد: {photo.width}×{photo.height} پیکسل"
    )


async def handle_sticker(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text("😊 استیکر قشنگی بود!")


def register_message_handlers(application: Application) -> None:
    application.add_handler(
        MessageHandler(filters.TEXT & ~filters.COMMAND, echo_text)
    )
    application.add_handler(MessageHandler(filters.PHOTO, handle_photo))
    application.add_handler(MessageHandler(filters.Sticker.ALL, handle_sticker))
