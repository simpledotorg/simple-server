# User Permissions

## Context
We are currently using a role based access control mechanism with the following roles
- Owner
- Organization Owner
- Supervisor
- Analyst
- Counsellor

As the application grows, we foresee an explosion in the roles and their abilities. This
would be very difficult to track with static roles. This also causes confusion to users
as we add more nuanced roles. 

## Decision
We propose moving to a permissions based access control model that can give granular access
to dashboard features. Each feature on the dashboard is backed by its on permission and user
access can be granted and revoked accordingly.

## Status
Superseded (by [012-simplified-user-permissions](012-simplified-user-permissions.md))

## Consequences
If each small feature on the dashboard has it's own permission, there would be an explosion in
the number of permissions making the system hard to use for the user, slow to maintain and develop,
and hard to debug. The granularity of the permissions must be choosen sensibly.
