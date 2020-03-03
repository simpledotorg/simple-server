# Single User Model

## Context
We currently have two separate models for Administrators (Admin) and Nurses (User)
to distinguish users of the dashboard and the app respectively. But there is an increasing
overlap between the two models.

- Some Administrators are using the app
- Access to dashboard needs to be audited similarly to syncing

## Decision
Combine User and Admin into a single User model, and have different authentication mechanism for
both these models.

- Authenticate syncing api using phone number authentication
- Authenticate dashboard access using email authentication

## Status
Accepted

## Consequences
