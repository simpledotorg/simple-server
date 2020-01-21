# No-op updates on discarded records

## Context

The addition of soft-deletes means that we need a way to deal with updates 
that can happen on top of the soft-deleted records.

An example could be follows,

* Nurse A from Facility X soft-deletes BP#1 and syncs to the server
* Nurse B from the same Facility X updates BP#1 without syncing changes from Nurse A
* When Nurse B syncs, her update to BP#1 will take place, although on a technically discarded record

However, all of this is an artifact of how the client deals with this situation.

The client currently does not send `deleted_at: nil` for an update to a non-discarded record. 
Since the app currently excludes all `null` values for serialization. 

If this behaviour changes in the future, wherein, the app sends `deleted_at: nil` for all requests, then we can get into
really hairy situations where one could _un-discard_ a record because of an un-synced update from a different client.

## Decision

Instead of relying on client-side behaviour, we will explicitly no-op the changes to discarded records.

We can do this simply by introducing another `merge_status` in the `Mergeable` concern as `:discarded`.

## Status

Accepted

## Consequences

1. If we take the 2-nurse example described above, as a result of ignoring (no-op) the update from Nurse B, 
her updates will be effectively lost and the sync will eventually make the record invisible.

2. We need to be careful with resources that do merges which involve dependencies, like `Patient` – so that we don't 
update the child-dependencies of discarded records (like an `Address`/`PhoneNumber` for a `Patient`).
