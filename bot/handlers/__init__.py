from bot.handlers.callbacks import register_callback_handlers
from bot.handlers.commands import register_command_handlers
from bot.handlers.messages import register_message_handlers


def register_handlers(application) -> None:
    register_command_handlers(application)
    register_callback_handlers(application)
    register_message_handlers(application)
