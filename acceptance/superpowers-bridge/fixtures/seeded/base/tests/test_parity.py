"""Adapters must report the same amount for the same input."""

from orders import payments


def test_card_and_invoice_agree():
    assert payments.card(10)["amount"] == payments.invoice(10)["amount"]
