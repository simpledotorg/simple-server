# Simplified User Permissions

## Context
We are currently using a permission based access control mechanism with a large 
number of permissions, to emulate the following 'roles':
- Owner
- Organization Owner
- Supervisor
- Analyst
- Counsellor

We've found this permission based mechanism hard to maintain due to a few reasons:
- The 'roles' are merely presets of permissions, and modifying the preset for a role also requires 
a corresponding data migration to update existing user's permissions
- We've allowed the possibility of 'custom' roles, where a given user can have a list of permissions 
that don't conform to any of the defined presets
- This is especially problematic when adding new 
permissions to the system, since it isn't easily possible to decide if a given custom user should get 
the new permission or not
- The specific implementation of our permission based system also added a fair amount of indirection 
and cognitive overhead which lead to a suboptimal developer experience 

We've also found that we don't actually need this level of flexibility in our access control model,
since most of our users have very normalised usage patterns.

## Decision
Move to a [Role Based Access Control](https://en.wikipedia.org/wiki/Role-based_access_control) system with the following roles to start with:

| Role                               | Description                                                                                                                    |
|------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|
| Manager                            | have full access to data and have permissions to manage other users and resources within the  resources where they have access |
| Viewer (all data)                  | have full access to data (including PII) within the resources where they have access                                           |
| Viewer (reports only)              | have access to reports within the resources where they have access                                                             |
| Call center (manage overdue lists) | can manage the overdue list within the resources where they have access                                                        |
| Power user                         | have full access to data, and user and resource management options in a given  deployment of the application                   |

![simplified-permissions](resources/user-permissions-2020.1.png)

Currently, `resources` can be instances of [`Organization`, `FacilityGroup`, `Facility`], but might include 
other regions like blocks, districts, states etc. in the future. Access on these resources cascades 
downwards (eg: access to an organization implies access to all facility groups and facilities within the organization)

## Status
Accepted

## Consequences
We no longer support customized permissions outside these defined roles
