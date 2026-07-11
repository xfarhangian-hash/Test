# ربات تلگرام

یک ربات تلگرام ساده با Python و کتابخانه [python-telegram-bot](https://github.com/python-telegram-bot/python-telegram-bot).

## قابلیت‌ها

- دستورات `/start`، `/help`، `/time`، `/about`، `/profile`
- دکمه‌های تعاملی (Inline Keyboard)
- پاسخ به پیام‌های متنی، عکس و استیکر
- رابط کاربری فارسی

## پیش‌نیازها

- Python 3.10 یا بالاتر
- یک توکن ربات از [@BotFather](https://t.me/BotFather)

## نصب و راه‌اندازی

### ۱. ساخت ربات در تلگرام

1. در تلگرام به [@BotFather](https://t.me/BotFather) بروید
2. دستور `/newbot` را بزنید
3. نام و username ربات را انتخاب کنید
4. توکن دریافتی را کپی کنید

### ۲. نصب وابستگی‌ها

```bash
python -m venv .venv
source .venv/bin/activate   # در ویندوز: .venv\Scripts\activate
pip install -r requirements.txt
```

### ۳. تنظیم توکن

```bash
cp .env.example .env
```

فایل `.env` را باز کنید و توکن را جایگزین کنید:

```
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHI...
```

### ۴. اجرای ربات

```bash
python -m bot.main
```

ربات را در تلگرام پیدا کنید و `/start` بزنید.

## ساختار پروژه

```
bot/
├── main.py              # نقطه ورود
├── config.py            # تنظیمات و env
└── handlers/
    ├── commands.py      # دستورات (/start, /help, ...)
    ├── callbacks.py     # دکمه‌های inline
    └── messages.py      # پیام‌های متنی، عکس، استیکر
```

## توسعه

برای افزودن دستور جدید، یک handler در `bot/handlers/commands.py` بسازید و آن را در `register_command_handlers` ثبت کنید.

## مجوز

MIT
