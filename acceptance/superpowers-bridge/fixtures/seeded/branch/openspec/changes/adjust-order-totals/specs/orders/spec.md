## MODIFIED Requirements

### Requirement: Orders are priced
The system SHALL compute the total of an order from its lines when the order is accepted, rounded to whole cents.

#### Scenario: Total sums the lines
- **WHEN** an order with two lines is accepted
- **THEN** its total equals the sum of the line amounts, rounded to whole cents
