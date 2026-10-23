"""Payment adapters."""


def card(amount: int) -> dict:
    return {"method": "card", "amount": amount}


def invoice(amount: int) -> dict:
    return {"method": "invoice", "amount": amount}


def wallet(amount: int) -> dict:
    return {"method": "wallet", "amount": amount}
