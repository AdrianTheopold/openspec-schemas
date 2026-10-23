# orders Specification

## Purpose
Defines how the order service prices and stores customer orders.

## Requirements

### Requirement: Orders are priced
The system SHALL compute the total of an order from its lines when the order is accepted.

#### Scenario: Total sums the lines
- **WHEN** an order with two lines is accepted
- **THEN** its total equals the sum of the line amounts
