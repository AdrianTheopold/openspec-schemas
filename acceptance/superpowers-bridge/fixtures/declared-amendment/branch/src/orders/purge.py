"""Removal of cancelled orders once they are no longer needed."""

from datetime import datetime, timedelta, timezone

from orders import store

RETENTION = timedelta(days=30)


def purge_cancelled(now: datetime | None = None) -> int:
    now = now or datetime.now(timezone.utc)
    purged = 0
    for order_id in store.all_ids():
        order = store.load(order_id)
        cancelled_at = order.get("cancelled_at") if order else None
        if cancelled_at is not None and now - cancelled_at >= RETENTION:
            store.delete(order_id)
            purged += 1
    return purged
