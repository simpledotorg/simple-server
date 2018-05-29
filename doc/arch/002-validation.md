# Validation

## Context

Incoming requests to the backend server must be validated to avoid
incomplete, and invalid data coming in.

Since most of the APIs will be asynchronous for the front-end, there
will be no user intervention when validation errors occur. Hence, such
validation must be coherent with the validation performed on the
mobile, front-end.

## Decision

Use swagger to formally record API specifications, and use the
internal JSON schema to validate incoming requests, using JSON schema
validators.

This makes validation errors predictable, and fixable during dev
time. Also, if we use swagger-codgen to generate clients for the
frontend, we would get compile time exceptions for type errors, etc.

Any additional validations that the backend performs, like conditional
requirement, must be made explicit in the API documentation, or raise
500s.

## Status

Accepted

## Consequences
