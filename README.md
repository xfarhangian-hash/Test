# ربات تلگرام — فوروارد پیام به مدیر

رباتی که **هر پیام دریافتی** را همراه با اطلاعات فرستنده به حساب تلگرام مدیر (`@MohsenFarhangian`) ارسال می‌کند.

## نحوه کار

1. کاربر پیامی (متن، عکس، فایل، استیکر و ...) به ربات می‌فرستد
2. ربات اطلاعات فرستنده را برای مدیر ارسال می‌کند
3. پیام اصلی به حساب مدیر **فوروارد** می‌شود

## پیش‌نیازها

- Python 3.10+
- توکن ربات از [@BotFather](https://t.me/BotFather)
- حساب مدیر: [@MohsenFarhangian](https://t.me/MohsenFarhangian)

## نصب

```bash
pip install -r requirements.txt
cp .env.example .env
```

فایل `.env` را ویرایش کنید:

```
TELEGRAM_BOT_TOKEN=توکن_ربات
ADMIN_USERNAME=MohsenFarhangian
```

## راه‌اندازی مدیر

> **مهم:** ربات نمی‌تواند مستقیماً با username پیام بفرستد؛ به `chat_id` عددی نیاز دارد.

**روش ۱ (ساده):** یک‌بار با حساب `@MohsenFarhangian` به ربات `/start` بزنید. شناسه چت شما خودکار ثبت می‌شود.

**روش ۲ (پایدار):** شناسه عددی را در `.env` قرار دهید:

```
ADMIN_CHAT_ID=123456789
```

شناسه را از [@userinfobot](https://t.me/userinfobot) یا دستور `/myid` دریافت کنید.

## اجرا

```bash
python -m bot.main
```

## ساختار

```
bot/
├── main.py
├── config.py
├── services/
│   └── forwarder.py    # منطق فوروارد به مدیر
└── handlers/
    ├── commands.py
    └── messages.py
```

## مجوز

MIT
