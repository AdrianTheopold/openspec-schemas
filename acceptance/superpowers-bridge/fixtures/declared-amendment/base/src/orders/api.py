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
