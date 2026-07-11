from datetime import datetime
from zoneinfo import ZoneInfo

from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update
from telegram.ext import Application, CommandHandler, ContextTypes

WELCOME_TEXT = (
    "سلام {name}! 👋\n\n"
    "به ربات تلگرام خوش آمدید.\n"
    "از دکمه‌های زیر یا دستور /help استفاده کنید."
)

HELP_TEXT = (
    "📋 **راهنمای دستورات**\n\n"
    "/start — شروع و خوش‌آمدگویی\n"
    "/help — نمایش این راهنما\n"
    "/time — زمان فعلی (تهران)\n"
    "/about — درباره ربات\n"
    "/profile — اطلاعات پروفایل شما\n\n"
    "همچنین می‌توانید هر پیامی بفرستید تا پاسخ بگیرم."
)

ABOUT_TEXT = (
    "🤖 **درباره ربات**\n\n"
    "این یک ربات تلگرام نمونه است که با Python و "
    "کتابخانه python-telegram-bot ساخته شده.\n\n"
    "قابلیت‌ها:\n"
    "• پاسخ به دستورات\n"
    "• دکمه‌های تعاملی\n"
    "• پاسخ به پیام‌های متنی\n"
    "• نمایش اطلاعات کاربر"
)


def _main_keyboard() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup(
        [
            [
                InlineKeyboardButton("⏰ زمان", callback_data="time"),
                InlineKeyboardButton("👤 پروفایل", callback_data="profile"),
            ],
            [
                InlineKeyboardButton("📋 راهنما", callback_data="help"),
                InlineKeyboardButton("ℹ️ درباره", callback_data="about"),
            ],
        ]
    )


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user = update.effective_user
    name = user.first_name if user else "دوست من"

    await update.message.reply_text(
        WELCOME_TEXT.format(name=name),
        reply_markup=_main_keyboard(),
    )


async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text(HELP_TEXT, parse_mode="Markdown")


async def about(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text(ABOUT_TEXT, parse_mode="Markdown")


async def time_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    now = datetime.now(ZoneInfo("Asia/Tehran"))
    text = f"🕐 زمان فعلی تهران:\n`{now.strftime('%Y/%m/%d — %H:%M:%S')}`"
    await update.message.reply_text(text, parse_mode="Markdown")


async def profile(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user = update.effective_user
    if not user:
        await update.message.reply_text("اطلاعات کاربر در دسترس نیست.")
        return

    username = f"@{user.username}" if user.username else "—"
    text = (
        "👤 **پروفایل شما**\n\n"
        f"• نام: {user.full_name}\n"
        f"• نام کاربری: {username}\n"
        f"• شناسه: `{user.id}`"
    )
    await update.message.reply_text(text, parse_mode="Markdown")


def register_command_handlers(application: Application) -> None:
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(CommandHandler("about", about))
    application.add_handler(CommandHandler("time", time_command))
    application.add_handler(CommandHandler("profile", profile))
