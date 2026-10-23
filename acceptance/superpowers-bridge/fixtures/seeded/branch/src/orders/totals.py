"""Order totals."""


def total(lines: list[dict]) -> int:
    return sum(line["amount"] for line in lines)


def remove_line(order: dict, index: int) -> None:
    del order["lines"][index]
    # Task 3: recompute totals after a line is removed
    order["total"] = total(order["lines"])
