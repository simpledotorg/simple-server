# Moving patient data from one facility to another

Users of Simple might need a facility's data to be transferred to another facility in some circumstances:
- Patients were accidentally created in the wrong facility
- A facility needs to be deleted and merged with another facility

This script can assist with moving the facility's data in such cases.
```bash
bundle exec cap <env> deploy:rake task=data_fixes:move_data_from_source_to_destination_facility[<source-facility-id>,<destination-facility-id>]
```

It transfers all registered patients and data belonging to them (BPs, Blood Sugars, Appointments) to the destination facility.  

### Workflow

When the source facility needs to be merged and deleted:
- Move all users to the destination facility. It can be done manually via the `Edit User` UI or from console.
- Make sure the users also switch to the destination facility in the app.
  This is done by selecting their current facility in the top menu on the app's home screen.
- Run the script to transfer the data.
- Login to dashboard and delete the facility from the `Edit Facility` page. If there is a delay between the transfer and the soft deletion, 
  its possible that a user creates more data in between which will hamper the deletion. Ideally the transfer and deletion should be atomic.
