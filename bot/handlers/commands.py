from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes

from bot.config import get_settings
from bot.services.forwarder import get_admin_chat_id, is_admin, register_admin
from bot.utils.rtl import rtl

WELCOME_TEXT = rtl(
    "سلام {name}! 👋\n\n"
    "پیام‌های شما به مدیر ارسال می‌شود.\n"
    "هر متن، عکس، فایل یا استیکری که بفرستید، "
    "مستقیماً به حساب @{admin} ارسال می‌شود."
)

ADMIN_WELCOME_TEXT = rtl(
    "سلام {name}! 👋\n\n"
    "شما به‌عنوان مدیر (@{admin}) ثبت شدید.\n"
    "از این پس تمام پیام‌های کاربران به این حساب ارسال می‌شود.\n\n"
    "شناسه چت شما: {chat_id}"
)

HELP_TEXT = rtl(
    "📋 راهنما\n\n"
    "هر پیامی که به این ربات بفرستید، "
    "همراه با اطلاعات فرستنده به مدیر ارسال می‌شود.\n\n"
    "دستورات:\n"
    "/start — شروع\n"
    "/help — نمایش این راهنما\n"
    "/myid — نمایش شناسه چت شما (فقط مدیر)"
)

ABOUT_TEXT = rtl(
    "🤖 درباره ربات\n\n"
    "این ربات پیام‌های دریافتی را به حساب "
    "تلگرام مدیر (@{admin}) فوروارد می‌کند."
)


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    settings = get_settings()
    user = update.effective_user
    name = user.first_name if user else "دوست من"

    if is_admin(user, settings):
        register_admin(update, context)
        await update.message.reply_text(
            ADMIN_WELCOME_TEXT.format(
                name=name,
                admin=settings.admin_username,
                chat_id=update.effective_chat.id,
            ),
        )
        return

    await update.message.reply_text(
        WELCOME_TEXT.format(name=name, admin=settings.admin_username)
    )


async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text(HELP_TEXT)


async def about(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    settings = get_settings()
    await update.message.reply_text(
        ABOUT_TEXT.format(admin=settings.admin_username),
    )


async def myid(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    settings = get_settings()
    user = update.effective_user

    if not is_admin(user, settings):
        await update.message.reply_text(
            rtl("این دستور فقط برای مدیر در دسترس است.")
        )
        return

    register_admin(update, context)
    admin_chat_id = get_admin_chat_id(context, settings)
    await update.message.reply_text(
        rtl(
            f"شناسه چت شما: {admin_chat_id}\n"
            f"نام کاربری مدیر: @{settings.admin_username}"
        ),
    )


def register_command_handlers(application: Application) -> None:
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(CommandHandler("about", about))
    application.add_handler(CommandHandler("myid", myid))
