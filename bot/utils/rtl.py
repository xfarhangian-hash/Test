RTL_START = "\u202b"
RTL_END = "\u202c"


def rtl(text: str) -> str:
    """Wrap text for right-to-left display in Telegram."""
    return f"{RTL_START}{text}{RTL_END}"
