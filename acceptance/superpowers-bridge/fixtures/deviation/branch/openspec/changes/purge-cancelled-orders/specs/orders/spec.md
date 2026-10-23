## ADDED Requirements

### Requirement: Cancelled orders are purged after 30 days
The system SHALL remove a cancelled order from the store once 30 days have passed since it was cancelled.

#### Scenario: Old cancelled order is purged
- **WHEN** the purge runs and an order was cancelled more than 30 days earlier
- **THEN** the order is removed and can no longer be retrieved

#### Scenario: Recent cancelled order is kept
- **WHEN** the purge runs and an order was cancelled less than 30 days earlier
- **THEN** the order can still be retrieved by its identifier

### Requirement: A cancelled order can be deleted through the API
The system SHALL let a client delete a cancelled order through the public API, and SHALL refuse to delete an order that is not cancelled.

#### Scenario: Delete a cancelled order
- **WHEN** a client deletes a cancelled order through the public API
- **THEN** the order is removed and can no longer be retrieved

#### Scenario: Delete an order that is not cancelled
- **WHEN** a client deletes an order that is not cancelled
- **THEN** the system refuses the request and leaves the order unchanged

## MODIFIED Requirements

### Requirement: Orders are stored
The system SHALL store every accepted order, including cancelled ones until they are purged or deleted, so that it can be retrieved by its identifier.

#### Scenario: Stored order is retrievable
- **WHEN** an order is accepted or later cancelled, and has not been purged or deleted
- **THEN** the order can still be retrieved by its identifier

#### Scenario: Unknown identifier
- **WHEN** an order is requested with an identifier that was never accepted
- **THEN** the system reports that no such order exists
