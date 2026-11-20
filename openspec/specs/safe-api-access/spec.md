# safe-api-access Specification

## Purpose

Defines how the addon reads game API values on a client that can return hidden "secret" values, so that no read can raise an error or act on a value addon code is not allowed to inspect.

## Requirements

### Requirement: Secret values are treated as unreadable
The addon SHALL treat any value the client marks as secret as unreadable, and SHALL NOT compare, branch on, or print its contents. On clients without secret-value support, every value SHALL be considered readable.

#### Scenario: Client reports a secret value
- **WHEN** a game API returns a value the client marks as secret
- **THEN** the addon treats the read as failed and does not inspect the value

#### Scenario: Client has no secret-value API
- **WHEN** the client does not provide a secret-value check
- **THEN** all returned values are treated as readable

#### Scenario: The secret-value check itself fails
- **WHEN** the secret-value check errors or returns a non-boolean
- **THEN** the value is treated as unreadable

### Requirement: API calls never raise errors
Every game API call used for decisions SHALL be protected so that an error, a missing function, or a secret function reference results in a failed read instead of a Lua error.

#### Scenario: API function is missing
- **WHEN** a decision depends on an API that does not exist on the client
- **THEN** the read fails quietly and the decision continues with its unreadable-value path

#### Scenario: API call errors
- **WHEN** a game API raises an error during a read
- **THEN** the error is caught and the read is treated as failed

### Requirement: Diagnostic output never exposes secret values
When values are written to chat or to logs, secret values SHALL be shown as `SECRET`, nil as `nil`, values that cannot be converted to text as `UNPRINTABLE`, and missing APIs as `MISSING API`. Errors SHALL be shown as `ERROR: <description>`.

#### Scenario: Logging a secret unit name
- **WHEN** a diagnostic line includes a unit name that is secret
- **THEN** the line shows `SECRET` in its place

#### Scenario: Probing a missing API
- **WHEN** the probe reports on an API the client lacks
- **THEN** the line shows `MISSING API`
