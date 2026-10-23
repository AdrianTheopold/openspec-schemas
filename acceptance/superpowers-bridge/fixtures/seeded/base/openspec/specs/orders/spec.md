# orders Specification

## Purpose
TBD - created by archiving change add-orders. Update Purpose after archive.

## Requirements

### Requirement: Orders are stored
The system SHALL store every accepted order so that it can be retrieved by its identifier.

#### Scenario: Stored order is retrievable
- **WHEN** an order is accepted
- **THEN** the order can be retrieved by its identifier

### Requirement: Orders are priced
The system SHALL compute the total of an order from its lines when the order is accepted.

#### Scenario: Total sums the lines
- **WHEN** an order with two lines is accepted
- **THEN** its total equals the sum of the line amounts

### Requirement: Orders can be listed
The system SHALL provide `list_orders()` to return every stored order.

#### Scenario: Listing returns stored orders
- **WHEN** two orders are stored and `list_orders()` is called
- **THEN** both orders are returned

### Requirement: Orders expose their totals
`list_orders()` SHALL return each order together with its total.

#### Scenario: Listed orders carry totals
- **WHEN** an order with a total of 30 is stored and `list_orders()` is called
- **THEN** the returned order shows a total of 30
