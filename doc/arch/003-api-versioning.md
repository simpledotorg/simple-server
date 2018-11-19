# API and Schema Versioning

## Status

Proposed

## Context

As the application evolves over time, we will
- add more apis
- change the behaviour of existing apis
- deprecate unused apis
- add fields to requests and response schemas
- modify existing fields in the schema

This requires the clients of the api to update as the application updates as well. 
However, the clients that use our application are not always under our control. This is especially true in the case of mobile clients.

We use api and schema versioning, to avoid making breaking changes, and further decoupling clients from our application, 

## Decision

The schema is versioned with the format 'X.y' where 'X' is equivalent to the minor version and 'y' is equivalent to the patch version in semantic versioning.
When the schema changes in a backwards compatible way, we update the patch version for the schema. Any breaking changes, require us to update the minor version.
For example: adding new models, new feilds to existing models only require incrementing the patch version, but breaking changes like renaming existing feilds, changing their data type, etc. require us to increment the minor version.

The api version is derived from the schema version, and is simply the minor version of the schema. 
Adding a new api is backwards compatible and don't require us to increment the api verion. Any breaking change to the api requires us to publish a new api version. It should be noted that all other endpoints, except for the new breaking changes, should be compatible with the previous version of the API. 

We also maintain the code in the latest api, and update older versions to maintain backwards compatibility.
## Consequences

- Any change to an existing api, should be forethought.
- Collorary: Adding new apis is preferrred over updating existing ones.
- We need to maintain controllers and views for every api version. This can cause code duplication across versions.
- We need to measure the number of clients using each version of the api so we can deprecate older apis.

## Examples

- Adding new enum value for a model field - `y -> y + 1`
- Adding fields to an existing model - `y -> y + 1`
- Adding a new api - `y -> y + 1`
- Modifying behavior of api in a backwards incompatible manner - `X -> X + 1`
- Remove or modify enum values in a model -> `X -> X + 1`
- Remove a field from a model -  `X -> X + 1`
- Change the type of a field -  `X -> X + 1`