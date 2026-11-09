# orders Specification

## Purpose
Defines how the order service records customer orders, lets an unshipped order be cancelled, and keeps every order available for later lookup.

## Requirements

### Requirement: Orders are stored
The system SHALL store every accepted order, including cancelled ones, so that it can be retrieved by its identifier.

#### Scenario: Stored order is retrievable
- **WHEN** an order is accepted or later cancelled
- **THEN** the order can still be retrieved by its identifier

#### Scenario: Unknown identifier
- **WHEN** an order is requested with an identifier that was never accepted
- **THEN** the system reports that no such order exists

### Requirement: Orders can be cancelled before shipping
The system SHALL allow an order to be cancelled while it has not shipped.

#### Scenario: Cancel an unshipped order
- **WHEN** a customer cancels an order that has not shipped
- **THEN** the order is marked as cancelled
