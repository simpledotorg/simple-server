# Synchronize data between device and server

## Context

Network connectivity on phones in rural areas can be low, and
patchy. So, the app needs to work offline, as much as possible. The
sync mechanism exists to allow sharing records of patients, blood
pressures, etc across devices.

We need to accommodate cases where patients, and nurses move across
facilities multiple times during a week.

## Decision

### Mechanism

1. Send records from device to server

The device needs to keep track of records that need to be
synced. These can be new records, or records that have one or more
fields updated. These records need to be formatted into the payload
schemas as defined in the individual APIs below. The API will not
differentiate between new and updated records; this is handled by the
server.  These payloads then need to be sent in batches, where each
batch is inherently independent of the previous one. However, it is
important to _send_ all records that need syncing, before fetching
records from the server.

2. Fetch records from server to device

When fetching records for the first time, the `first_time` query
parameter should be set. The server will then send back a number of
records as defined by the `number_of_records` query parameter. This is
essentially the \"batch_size\". The first response also includes a
`latest_record_timestamp`, that needs to be sent with the next
request, in order to retrieve more records from the server. If there
are no more records to be sent from the server, it returns an empty
list.

3. Merge records on device

After receiving records from the server, the device will match the
records in the local database using the ID field of the entity, and
update them to the server's version. If the local record in the
database is pending a sync, it will not update it. The merging of
records will be handled only by the server.

The server may send back the same record multiple times, so updating
records on the device needs to be idempotent.

### Levers

Physical resource constraints such as battery life, or network are not
under our control. In order for the app to adapt well to the
constraints, we need to have knobs on:

1. Batch size: how many records to send or fetch
2. Sync frequency: how often sending or fetching happens

Preferably, these levers are modifiable at run-time, per device.

## Status

Accepted

## Consequences

The computation of records to be sent is currently based on the
`updated_at` field on the server, and the `processed_since` in the
query parameters. This implies, that if there are multiple records
with the same timestamp, the same record will be sent multiple times.
And if there are as many records with the same timestamp as the batch
size, the same response is sent over and over again, effectively
breaking the batching mechanism.

This implies we need sequencing of records on the server. We rely on
timestamps for this now. But we could have a separate sequence, or an
immutable and sequenced audit log to do this.
