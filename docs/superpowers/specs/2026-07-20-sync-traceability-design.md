# Sync Traceability Design

## Goal

Add a reusable observability framework that traces a request across meaningful application boundaries. The first migration covers all Simple API v3 and v4 sync endpoints and emits correlated structured logs and Prometheus metrics without exposing clinical data.

## Design principles

- Boundaries are explicit in application code.
- Every traced boundary emits paired start and finish events.
- Rails request IDs correlate all events produced by one request.
- Logs may contain operational metadata, but not clinical payloads.
- Metric labels have bounded cardinality.
- Observability must not change request behavior.
- Existing metrics remain available while callers migrate.

## Architecture

`Traceability.trace(boundary:, operation:, attributes:) { ... }` is the application-facing API. It publishes start and finish events through `ActiveSupport::Notifications`. The finish event is published from an `ensure` block and includes elapsed time measured with a monotonic clock.

Separate notification subscribers produce structured Ougai logs and Prometheus metrics. This keeps callers independent of output implementations and allows future subscribers without changing sync code.

A controller concern wraps sync actions as request boundaries. Shared sync orchestration methods and specialized endpoints add explicit data-boundary wrappers. Active Record is not globally instrumented or monkey-patched.

Existing Lograge request completion logs remain unchanged in the first iteration.

## Event lifecycle

For each boundary:

1. Build safe context from the request and explicit caller attributes.
2. Publish a start event.
3. Run the operation.
4. Publish a finish event with duration and outcome.
5. Return the operation result or re-raise its original exception unchanged.

Subscriber failures are isolated and never fail the traced operation.

### Outcomes

- `success`: the operation completed. A completed batch with invalid records is successful and reports a non-zero `error_count`.
- `error`: the operation raised, or a request boundary completed with an HTTP 4xx/5xx response.

## Correlation and structured logs

The primary correlation key is `request.request_id`. A client idempotency key is included when one is present, but is not required.

Request events use `msg: "SIMPLE-REQUEST-LINE"` and data events use `msg: "SIMPLE-DATA-LINE"`.

Common fields:

- `phase`: `start` or `finish`
- `request_id`
- `idempotency_key`, when present
- `boundary`
- `operation`
- authenticated user and facility IDs, when available
- `outcome`, on finish
- `duration_ms`, on finish
- `error_class`, when an operation raises

Request fields:

- controller and action
- HTTP method and path
- response status, on finish

Data fields:

- model or resource
- input, output, and error counts, when applicable
- current record ID on batch failure, when available

The trace framework must never log:

- request or response bodies
- clinical attributes
- process-token contents
- access tokens or authorization headers
- exception messages or backtraces

IDs are log-only. They are not Prometheus labels.

## Metrics

Finish events produce:

- `simple_boundary_operations_total`
- `simple_boundary_duration_seconds`

Allowed labels are:

- boundary
- operation
- resource
- outcome

Operation and resource names are code-defined values, never request-derived values. The existing `sync_to_user_operation_duration_seconds` metric remains during migration so current dashboards and alerts do not break.

## Initial coverage

The controller concern covers every API v3 and v4 action named `sync_from_user` or `sync_to_user`, including custom endpoints that do not use the standard orchestration methods.

### Request lifecycle

- ingress
- authentication and request-context resolution
- sync orchestration
- response rendering
- egress

### Push lifecycle

- payload batch accepted
- validation, transformation, and merge batch
- audit persistence
- validation-result aggregation
- response serialization

### Pull lifecycle

- process-token decoding
- sync-scope selection
- current-facility query
- other-facility query
- combined record retrieval
- audit-job enqueue
- batch transformation
- process-token encoding
- response serialization

Specialized sync endpoints receive explicit wrappers for equivalent operations where they bypass shared methods.

Batch boundaries report aggregate counts. They do not emit per-record success logs. When a batch raises while processing a record, the finish event includes that record's ID when it can be obtained safely.

## Error handling

The traced operation is authoritative: its return value and exceptions are preserved. Finish publication occurs in `ensure`, and tracing infrastructure errors are suppressed so observability cannot alter sync behavior.

No sensitive exception text is copied into trace events. Existing application error reporting remains responsible for full diagnostic exceptions and backtraces.

## Testing

Unit tests for the trace API and subscribers cover:

- paired start and finish events
- monotonic duration
- success and error outcomes
- preservation of return values and exceptions
- subscriber-failure isolation
- structured log fields
- metric names and bounded labels

Request and controller tests cover representative v3 and v4 push and pull requests, plus custom sync endpoints. They verify request-ID correlation, batch counts, HTTP error outcomes, and failing-record IDs.

Security-focused assertions verify that clinical fields, process tokens, access tokens, authorization headers, exception messages, and response bodies never appear in trace logs.

## Non-goals

- distributed tracing across other services
- requiring client idempotency keys
- tracing every Ruby or Active Record method
- per-record success logs
- replacing Lograge
- removing or renaming existing metrics
- instrumenting non-sync application paths in the first migration

## Extension path

After sync coverage is validated in production, other controllers and service boundaries can adopt the same explicit wrapper. New boundary and resource names must remain code-defined and low-cardinality.
