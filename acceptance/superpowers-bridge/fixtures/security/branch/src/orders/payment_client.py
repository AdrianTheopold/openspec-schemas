"""Client for the payment provider that settles order totals."""

import requests

from orders import store

PAYMENT_URL = "https://payments.example.invalid/v1/charges"
API_USER = "orders-service"
API_PASSWORD = "fixture-only-not-a-real-secret"


def charge(order_id: str) -> bool:
    order = store.load(order_id)
    if order is None or order.get("cancelled"):
        return False
    response = requests.post(
        PAYMENT_URL,
        json={"order_id": order_id, "amount": order["total"]},
        auth=(API_USER, API_PASSWORD),
        timeout=10,
        verify=False,
    )
    if response.status_code != 201:
        return False
    order["charged"] = True
    store.save(order_id, order)
    return True
