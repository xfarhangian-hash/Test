import json
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

STORE_PATH = Path(__file__).resolve().parent.parent.parent / ".reply_map.json"


def _load() -> dict[str, int]:
    if not STORE_PATH.exists():
        return {}
    try:
        raw = json.loads(STORE_PATH.read_text(encoding="utf-8"))
        return {str(k): int(v) for k, v in raw.items()}
    except (json.JSONDecodeError, ValueError, TypeError):
        logger.warning("Could not read reply map, starting fresh.")
        return {}


def _save(data: dict[str, int]) -> None:
    STORE_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def _key(admin_chat_id: int, message_id: int) -> str:
    return f"{admin_chat_id}:{message_id}"


def link_message(admin_chat_id: int, message_id: int, user_chat_id: int) -> None:
    data = _load()
    data[_key(admin_chat_id, message_id)] = user_chat_id
    _save(data)


def get_user_chat_id(admin_chat_id: int, message_id: int) -> int | None:
    return _load().get(_key(admin_chat_id, message_id))
