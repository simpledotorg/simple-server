# Region level sync
September 2020 (accepted)

_This ADR has been added retroactively in Apr 2021 to capture our switch to block-level syncing._

## Context

Users in large districts reported that the Simple app was running very slow, making the app near-unusable.
The slowdown was correlated to the volume of patient data synced to the user’s phone. We realised that the amount of data being stored on the device had to be reduced for better long-term performance.

Currently we sync the entire district's records to a user's phone. Some of the large districts have upto 50,000 patients, which can amount to 400-500 MB of data.

A district typically has between 1-20 blocks. From trends in IHCI, we found that patients rarely move between facilities across blocks. Patients that have a BP taken in more than 1 block is around 2% or under, with the exceptions of: Sindhudurg (9.8%), Hoshiarpur (5.3%), Bathinda (3.1%).
This means that we can sync only a block's data to the user's phone and be reasonably confident about finding patients on the app.

## Decision

- The server will sync records from the user's block instead of the entire district.
  Specifically the following patients will be synced:
  - patients that registered at a facility in the same block,
  - patients that are assigned to a facility in the same block, and
  - patients that have an appointment scheduled at a facility in the same block.
- All other sync resources will return records belonging to these patients only.
- The sync mechanism should support the ability to adjust the sync radius to any sync region.
  This is important in case we need to change the kind of records that are synced to the app in the future.
  See [Block level sync manual](../wiki/adjusting-sync-boundaries.md) for how it works.

### On the app
- Users can continue selecting any facility in their district when switching facilities.
- Users can continue selecting any facility in their district when scheduling a patient’s next visit or preferred facility. 
- It is possible that a patient will visit a facility outside their block and their record will not be found on the user’s device. In this case the user should 
    - Scan the patient’s BP passport if they have one.
    - Register the patient again, as if they were new. Make sure to attach their existing BP passport to the registration.
    - The duplicate patient records will be merged by the Simple team later.

## Status

Accepted. This feature was released to all users by Feb 2020.

## Consequences

- The Simple app might not be able to find patients who moved from one block to another.
- Block is currently a freeform text field on the `Facility` model.
  It needs to be a first-class entity to make block-level syncing possible.
  This is introduced through the `Region` model.
- When a patient gets registered across blocks as a duplicate, we will need to identify them and merge their data.

