## ADDED Requirements

### Requirement: Order totals are rounded
The system SHALL round the total of an order to whole cents before storing it.

#### Scenario: Fractional cents are rounded
- **WHEN** an order whose lines sum to 10.005 is accepted
- **THEN** its stored total is 10.01
