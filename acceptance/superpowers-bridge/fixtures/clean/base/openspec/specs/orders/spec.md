# orders Specification

## Purpose
Defines how the order service records customer orders and keeps them available for later lookup.

## Requirements

### Requirement: Orders are stored
The system SHALL store every accepted order so that it can be retrieved by its identifier.

#### Scenario: Stored order is retrievable
- **WHEN** an order is accepted
- **THEN** the order can be retrieved by its identifier

#### Scenario: Unknown identifier
- **WHEN** an order is requested with an identifier that was never accepted
- **THEN** the system reports that no such order exists
