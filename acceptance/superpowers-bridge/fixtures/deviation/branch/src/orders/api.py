"""Public HTTP routes of the order service."""

from orders import store

ROUTES = {}


def route(method: str, path: str):
    def register(handler):
        ROUTES[(method, path)] = handler
        return handler

    return register


@route("GET", "/orders/{order_id}")
def get_order(order_id: str):
    order = store.load(order_id)
    return (200, order) if order is not None else (404, None)


@route("DELETE", "/orders/{order_id}")
def delete_order(order_id: str):
    # Only a cancelled order may be deleted, so an order that is still being
    # fulfilled can never disappear from under the warehouse.
    order = store.load(order_id)
    if order is None:
        return (404, None)
    if not order.get("cancelled"):
        return (409, None)
    store.delete(order_id)
    return (204, None)
