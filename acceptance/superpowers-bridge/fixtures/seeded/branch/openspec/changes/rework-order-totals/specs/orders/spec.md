## ADDED Requirements

### Requirement: Orders record their fulfilment history
The system MUST record every fulfilment event of an order, and each event MUST carry the time at which it happened, and each event MUST name the actor that caused it, and the history MUST keep events in the order they happened, and the history MUST stay readable for as long as the order itself is stored, including after the order has been cancelled, shipped, returned or refunded, so that support staff can reconstruct what happened to an order at any later point, even when a refund is issued weeks after delivery of the goods.

#### Scenario: Events are listed in order
- **WHEN** an order is shipped and then returned
- **THEN** its history lists the shipment before the return

### Requirement: Orders are stored
The system SHALL keep every stored order as an immutable document.

#### Scenario: Order is stored
- **WHEN** an order is placed
- **THEN** it is stored as an immutable document.

### Requirement: Orders report their totals
The system SHALL report the total of every order.

#### Scenario: Totals are visible
Staff can see the total of an order in the order summary.

#### Notes
- **WHEN** an order is placed in a foreign currency
- **THEN** its total is shown in that currency

### Requirement: Orders cannot be deleted
This change SHALL add no deletion endpoint.

#### Scenario: Deletion is unavailable
- **WHEN** a client asks to delete an order
- **THEN** the system reports that the operation does not exist

### Requirement: Order validation (D9)
The system SHALL validate every order before storing it.

#### Scenario: Invalid order
- **WHEN** an order without lines is submitted
- **THEN** the order is rejected, because design D4 keeps validation in the gateway.

### Requirement: Payment adapters agree
The parity suite MUST keep all three payment adapters in agreement.

#### Scenario: Adapters report the same amount
- **WHEN** the same amount is charged through each adapter
- **THEN** each adapter reports that amount

## MODIFIED Requirements

### Requirement: Orders are priced
The system SHALL compute the total of an order from its lines when the order is accepted. Every order MUST carry a checksum of its lines.

#### Scenario: Total sums the lines
- **WHEN** an order with two lines is accepted
- **THEN** its total equals the sum of the line amounts

## REMOVED Requirements

### Requirement: Orders can be listed
**Reason**: The listing operation `list_orders()` is replaced by a paged query.
**Migration**: Use the paged query.
