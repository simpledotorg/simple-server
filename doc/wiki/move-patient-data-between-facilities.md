# Moving patient data from one facility to another

There are some circumstances where a facility's data might need to be transferred to another facility:
- Patients were accidentally created in the wrong facility
- A facility needs to be deleted and merged with another facility

This script can assist with transferring patient data in such cases.
```bash
bundle exec cap india:production deploy:rake task=data_fixes:move_data_from_source_to_destination_facility[<source-facility-id>,<destination-facility-id>]
```

### Caveats

- This does not transfer users from the source facility. In case users also need to be moved to the destination
facility, it can be done manually via the `Edit User` UI or from console.
- In case the source facility needs to be deleted, make sure the users also switch their facility in the app.
If there is a delay between the transfer and the soft deletion, its possible that a user creates more data in between which will hamper the deletion.
Ideally the transfer and deletion should be atomic.
