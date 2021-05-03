# Adjusting sync boundaries with Region level sync

Mobile devices have limited storage and there's a limit to how much data the android app can reasonably operate with.
Simple provides a way to adjust the number of records that are synced to the app by picking a "sync region". 
A sync region can be any region in the `Region` hierarchy (state, district, block).

This is a guide on how region level sync works and how to transition from one using one sync region to another sync region.

### At the heart of it
- The server sets the sync region for each facility by setting a `sync_region_id` in the facility payload.
  For block sync this is the the region ID of the facility's block.
- The app picks the current facility's `sync_region_id` as the sync region.
- The app requests for the sync region's records to be synced by sending the `sync_region_id` in the `X-SYNC-REGION-ID` header.
- The server returns data for the requested sync region's `syncable_patients`.
  The criteria for selecting these patients is currently defined [in the Region model](https://github.com/simpledotorg/simple-server/blob/5a6416760e016a2ba2d12f46e46135d11927497c/app/models/region.rb#L130).

#### Notes
- Currently only blocks and districts are supported as valid sync regions.
- We default to `FacilityGroup` records for old apps that don't support region level sync. This can be deprecated once all the apps have moved to
a region level sync compatible version.

### Moving from one region to another

To start using a different region as the sync region, setting the right `sync_region_id` in the facility payload will suffice.

- When the sync region is changed, it requires a resync so that all records from the other sync region can be synced to the app.
- The server detects if an app needs to resync by checking if there is a mismatch in the app's sync region in the last request (`sync_region_id` from the process token)
  and the region the app has requested (in the header).
- When the app detects a change in sync region, it triggers a task to purge stuff outside the new sync region. 
  Details of the purge mechanism on the app are [here](https://app.clubhouse.io/simpledotorg/story/1413/regularly-purge-data-outside-the-current-sync-group).
- It is important to keep in mind that changing the sync region causes apps to resync.
  Releasing such a change will cause a spike in sync traffic. Ideally it should be rolled out slowly under a feature flag.
