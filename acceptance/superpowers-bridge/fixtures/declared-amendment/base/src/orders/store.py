"""In-memory order storage."""

_orders: dict[str, dict] = {}


def save(order_id: str, order: dict) -> None:
    _orders[order_id] = order


def load(order_id: str) -> dict | None:
    return _orders.get(order_id)
