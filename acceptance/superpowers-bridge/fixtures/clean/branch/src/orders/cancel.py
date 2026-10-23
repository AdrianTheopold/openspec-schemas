"""Order cancellation."""

from orders import store


def cancel(order_id: str) -> bool:
    order = store.load(order_id)
    # Shipped orders cannot be recalled, so refusing here keeps the stored
    # state consistent with what the warehouse has already done.
    if order is None or order.get("shipped"):
        return False
    order["cancelled"] = True
    store.save(order_id, order)
    return True
