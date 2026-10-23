"""In-memory order storage."""

_orders: dict[str, dict] = {}


def save(order_id: str, order: dict) -> None:
    # Store a copy so that a caller who keeps editing its dict after saving
    # cannot change the stored order behind the store's back.
    _orders[order_id] = dict(order)


def load(order_id: str) -> dict | None:
    return _orders.get(order_id)
