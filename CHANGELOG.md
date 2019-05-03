# Unreleased
### Added 
### Changed
### Fixed
### Deprecated 
### Removed 
### Security

# 2019-05-03-1
### Added 
### Changed
### Fixed
- Allow Org Owners to create Facility Groups
- Fix the duplication of appointments in the Overdue tab
### Deprecated 
### Removed 
### Security


# 2019-04-30-1
## Portal
### Added
### Changed
### Fixed
### Deprecated
### Removed
### Security

## Api
### Added
- Appointment type as part of the API sync payload
### Changed
### Fixed
### Deprecated
### Removed
### Security

# 2019-04-29-1
## Portal
### Added
- Added a favicon
### Changed
- Dashboard graphs improvements
- Soft delete for facility groups (if empty)
- Show stats for the previous day on the dashboard
- Improved the formatting of the approval list on the home screen
- Hide download button if no appointments present
### Fixed
- Use time range when showing user analytics on facilities dashboard
- Adherence tab: show enrolment date for patients without BP
### Deprecated
### Removed
### Security

## Api
### Added
- Add support for V3 api (Feature toggled off)
- Add API support for Patient Business Identifiers (Feature toggled off)
- Allow sending SMS reminders in the specified locale
- Rake task to whitelist patient phone numbers on Exotel
- Add a script to generate WHO cohort reports
- Add generator for migrating to newer API version
### Changed
- Update links for the API docs to include v3
- Schedule cronjobs in Asia/Kolkata Timezone
### Fixed
### Deprecated
- Removed outdated rake tasks
### Removed
### Security

# 2019-04-16-2
## Portal
### Added
### Changed
### Fixed
- Hide unnecessary panels from dashboard
- Allow analysts and supervisors to view facility groups
### Deprecated
### Removed
### Security

## Api
### Added
### Changed
### Fixed
### Deprecated
### Removed
### Security

# 2019-04-16-1
## Portal
### Added
### Changed
### Fixed
### Deprecated
### Removed
### Security

## Api
### Added
### Changed
- Eager load patient address and phone number for syncing to user
- Make sync_to_user audit log creation async
- Disable audit log creation for facility sync
- Disable audit log creation for protocol sync
- Making the AuditLog insert bulk inserts for fetch
### Fixed
### Deprecated
### Removed
### Security

# 2019-04-12-2
## Portal
### Added
### Changed
### Fixed
### Deprecated
### Removed
### Security

## Api
### Added
### Changed
- Mark `appointment_type` column of appointments as non-null.
### Fixed
### Deprecated
### Removed
### Security

# 2019-04-12-1
## Portal
### Added
- Adding patient record creation date as enrolment date for adherence tab
- Add pagination to the AuditLogs index view
- Add views for whatsapp graphics for facility and facility groups
- Add a job to warmup analytics cache
### Changed
- Cleaned up and simplified managing organizations, facility groups and facilities.
- Don't allow facilities with associated records to be deleted
- Don't allow orgs with facility groups to be deleted
- Separated org management for owners
- Improve user and facility lists
### Fixed
- Fix missing hamburger icon in web view on dashboard
- Fix FacilityGroup and Organization ordering on dashboard
- Fix misplaced assignment while setting patients status to dead
- Fixed facility link paths
- Fix recorded patients count on the dashboard
### Deprecated
### Removed
### Security

## Api
### Added
- ExotelAPI to fetch the details of a call for the created call sessions
- Populate a CallLog at the end of a phone number masked session
- Adding the sidekiq monitoring route for owners only
- Add connection pooling and redis store for CallSession
- Add support to run sidekiq as a systemctl service
### Changed
- Enabled User Analytics API
- Grammar fixes in Help section
- Update Whatsapp support instructions
### Fixed
### Deprecated
### Removed
### Security

# 2019-04-10-1 [[CANCELLED] Impossible dates on Adherence followup screen]
## Portal
### Added
- Adding patient record creation date as enrolment date for adherence tab
- Add pagination to the AuditLogs index view
- Add views for whatsapp graphics for facility and facility groups
### Changed
### Fixed
- Fix missing hamburger icon in web view on dashboard
- Fix FacilityGroup and Organization ordering on dashboard
- Fix misplaced assignment while setting patients status to dead
### Deprecated
### Removed
### Security

## Api
### Added
- ExotelAPI to fetch call_details
- Populate the CallLog result from the terminate response
- Adding the sidekiq monitoring route for owners only
- Add connection pooling and redis store for CallSession
### Changed
- Enabled User Analytics API
### Fixed
### Deprecated
### Removed
### Security

# 2019-04-02-1
## Portal
### Added
- Add Patient Set Analytics for facilities and facility groups (Feature toggled off)
### Changed
- Improve entity ordering on dashboard
    - Organizations: order facility groups by name
    - Facility Groups: order facilities and users by name
    - Protocols: order protocols and protocol drugs by name
    - Users: order user by approval status + name
- Add patient already visited option to overdue list
- Updated UI for Facility Group and Facility Analytics (Feature toggled off)
### Fixed
- Fixed bug where marking patient as dead did not update the patient
### Deprecated
### Removed
### Security
- Upgrade to Rails 5.1.6.2
- Upgrade to devise 4.6.1

## Api
### Added
- Adding Rake task for creating automatic appointments for defaulters
- Added help docs and API endpoint
- API to serve nurse reports in progress tab on the app
- Phone number masking connect and terminate endpoints (Feature toggled off)
### Changed
- Whitelist age, date of birth, gender and status while anonymizing
### Fixed
### Deprecated
### Removed
### Security

# 2019-03-18-1
## Portal
### Added
- Added risk levels to the overdue list for patients with very high and high priority
### Changed
- Follow-up patients pages don't increment current_age when it is 0
- Allow editing a counsellor's facility groups
### Fixed
- Fix typo with ‘Adherence’
- Handle pagination when 'All' is selected, but records.size is 0
### Deprecated
### Removed
### Security

## Api
### Added
- Added rake task for anonymizing audit logs
- Added Rake task to fix scheduled appointments which are older than the latest BP reading
- API to create Exotel sessions for phone number masking (Feature toggle turned off)
### Changed
- Updated styles for Nurse reports (Feature toggle turned off )
### Fixed
### Deprecated
### Removed
### Security

# 2019-03-05-1
## Portal
### Added
- Added a setup script
### Changed
- Show logo and header colour as per current deployment env config
  - Change logo and banner (header) colour of simple server as per SIMPLE_SERVER_ENV
  - Added deployment env string to page title
### Fixed
- Correctly display BP counts for users who switch facilities
- Hide BPs with orphaned User associations
- List all users who have ever recorded a BP in each facility
### Deprecated
### Removed
### Security
- Upgrade bootstrap
  - In Bootstrap 4 before 4.3.1 and Bootstrap 3 before 3.4.1, XSS is possible in the tooltip or popover data-template attribute.
  - For more information, see: https://blog.getbootstrap.com/2019/02/13/bootstrap-4-3-1-and-3-4-1/

# 2019-02-28-1
## API
### Added
### Changed
### Fixed
- Fix list of organization owner emails while sending approval notifications
### Deprecated
### Removed
### Security

## Portal
### Added
- Allow filtering by facility in overdue patients and 48 hour follow up lists
- Allow patients per page selection in overdue patients and 48 hour follow up lists
### Changed
- Format the way we display when last BP was recorded
- Overdue patients and 48 hour follow up lists
  - Sort facilities by alphanumeric name
  - Made page titles and descriptions more concise
  - Copy fixes
### Fixed
- Fix errors in organization owner flows for creating facilties and faciltiy groups
- Anonymize users on sandbox
### Deprecated
### Removed
### Security

# 2019-02-20-1
## Portal
### Added
- 48 hour patient followup list for counsellors
### Changed
- Made formatting improvements to the Overdue list.
- Renamed it to Overdue for Follow-up, improved legibility, improved on mobile.
- Updated the confirmation dialog message after submitting the Overdue form.
- Show "No patients" if no patients are overdue at a clinic.
- Make User phone number comparision case insensitive for checking uniqueness
### Fixed
- Fixed overdue time so it never overlaps the patient name
### Deprecated
### Removed
### Security

# 2019-02-19-1
## Portal
### Added
### Changed
### Fixed
-  Bug fix: Invitation emails were being sent twice
### Deprecated
### Removed
### Security

# 2019-02-18-1
## Portal
### Added
- Add counsellor admin role
- Add Overdue Appointments dashboard page for counsellors
    - View patients with overdue appointments
    - Update appointments from dashboard similarly to android app
### Changed
- Updated routing to new simplified home page
- Added organization show and index controllers for analytics
- Move dashboard to facility group show controller for analytics 
- Skip authorization in facility group show for analytics
- Update navigation to better accommodate management menu items
- User approval is now shown in organization list views
- Human-friendly slugs in URLs for orgs, groups, and facilities
- Migrate from sass-rails to sassc-rails
- Make facility group description optional in form
- Display all facilities, users and protocols to owners
- Added pagination with kaminari in overdue appointments dashboard page
### Fixed
### Deprecated
### Removed
- Old admin dashboard view
### Security

## API
### Added
- Added API for Nurse Reports with inline JS and CSS
- Script to create anonymized data in sandbox environment
### Changed
- Protocol drugs are always ordered by updated_at when accessing from protocol association
### Fixed
### Deprecated
### Removed
### Security

# 2019-01-15-2
## Portal
### Added
### Changed
### Fixed
- Update controller allow creating new facility groups
### Deprecated
### Removed
### Security 

# 2019-01-15-1
## Portal
### Added
### Changed
### Fixed
- Fix organization owners policy to allow creating new records in their organizations
### Deprecated
### Removed
### Security

# 2019-01-14-1
## Portal
### Added
### Changed
- Move Invite Owner button before Invite Organization Owner on Admins page
- Display logged in admin's email id
- Admins can edit their users from the User Details page
- Add organization name to approval email body
- Dropdown to change user's facility is arranged in alphabetical order
- Ignore prefix Dr/Dr. when sorting facilities by name
- Organization Owners can access/edit all entities within their organizations
- Organization Owners can invite new admins to their organizations

### Fixed
- Fix inviting owners

### Deprecated
### Removed
### Security


# 2019-01-03-1

## Portal
### Added
- Add invitation policy

### Changed
- Scope records seen by an admin to their organizations
- Redirect and display flash message when Admin is unauthorized to access resource

### Fixed
- Fix bug in updating user's facility
- Fix edit organization link on organization index page

### Deprecated 
### Removed 
### Security

## API
### Added
### Changed
### Fixed
### Deprecated
### Removed 
### Security 


# 2019-01-01-1

## Portal
### Added
- Associate admins to facility groups
- Add a role for organization owners
- BCC organization owners in approval emails
- Associate facility groups with protocols

### Changed
- Only show users belonging to an admin's facility groups
- Remove user facilities model
- Update swagger docs
- Add deleted at to with_int_timestamps util
- Send approval emails only to the admins of a user's facility group
- Only show data facilities in the admins facility group
- Only show approval requests for users from the facility group
- Update show and edit views for admins
- Show separate dashboard to admin per facility group
- Return protocol id with facility sync api

### Fixed
- Fix facility group edit view

### Deprecated 
### Removed 
### Security

## API
### Added
### Changed
- Add org name to approval mails
- Approval email lists accessible facilities
- Add owner emails to bcc lists
- Sync only facilities with associated facility groups
- Allow soft deleting blood pressures
- Disable authentication for protocol syncing

### Fixed
- Add id to appointments error hash
- Fix 500 error in v2 protocol sync

### Deprecated
### Removed 
### Security 

# 2018-12-21-2

## Portal
### Added
- Organizations and Facility Groups, ability to create, update and delete them
- Roles to manage organizations and facilities
- Organize all punjab facilities under IHMI
### Changed
### Fixed
### Deprecated 
### Removed 
### Security

## API
### Added
- Add FACILITY_ID to sync API headers. Make this optional for v1 and required for v2
- Associate patient with registration user and registration facility
- User has a registration facility.
  - `facility_ids` is changed to `registration_facility_id` in v2 of `users/register`, and `users/find`
- Soft deletes (optional deleted_at field in all entities)
### Changed
- Restrict sycning of records to a users facility group
- Prioritise current facility sync for Patients, BPs, Drugs, and Appointments
- API schema now has process_token instead of processed_since
- Make diagnosed with hypertension a required field for medical history
- Update cancel reasons in appointments
  - Add 3 new reasons to v2, exclude them from v1, and coerce accordingly
  - Updation of cancelled appointments is disallowed in v1
### Fixed
- Report user id with extra args to sentry
### Deprecated
### Removed 
### Security 
- Upgrade activejob to fix vulnerability issue

# 2018-12-18-1

## Portal
### Added 
- Add patient visits to dashboard 
- Added an analyst role for read-only dashboard access 
### Changed
- Count unique patients per day instead of BPs 
- Extended daily stats to 21 days back 
- Fixed wrapping of text in the Users index
- UI Improvements
- Use India timezone in dashboard 
### Fixed
- Use AdminController for audit logs
### Deprecated 
### Removed 
### Security 
- [Security] Bump bootstrap from 4.1.1 to 4.1.3 

## API
### Added 
- Add email prefixes to approval request emails
- Multiple api versions
### Changed
- Allow null vaules for medical history questions
- Respond with false if medical history question is nil
- Update medical history questions from boolean to enum
### Fixed
### Deprecated 
### Removed 
### Security 
- Add EMAIL_SUBJECT_PREFIX to required config
- [Security] Bump loofah from 2.2.2 to 2.2.3 (#152)
- [Security] Bump rack from 2.0.5 to 2.0.6 (#158)

# 2018-10-08-3
## Portal 
### Fixed
- Fix patient count in dashboard
 
# 2018-10-08-2
## API
### Changed
- Update swagger.json

# 2018-10-08-1
## API
### Added
- Add diagnosed with hypertension to medical histories 
### Security
- Bump nokogiri from 1.8.2 to 1.8.4
- Bump ffi from 1.9.23 to 1.9.25

## Portal 
### Added
- Added route, controller, and views for admin dashboard
- Added a basic task list for approving sync requests
- Display control rate in the dashboard
- Add reason for denial when disabling access

# 2018-09-26-1
## API
### Added
- Document deployment process
- Upload beta 20 facilities
- Add api and schema specification for reset password api
 
### Changed
- Update appointments model

 
## Portal
### Fixed
Bug fixes on Admin UI

# 2018-09-17-1
## API

### Changed 

- User can belong to multiple facilities
- Rename tags in swagger schema

### Fixed

- Ensure config for required keys exists before app starts
- Reset user access token every time the user logs in (only occurs on a new device)
- Don't reset access token when enabling access, only update sync status
- Remove sms notification to user when access is enabled
- Redirect to login when admin is not logged in
- Add access token to the registration response
- Remove authentication for ping checks
- Only display links that the admin can access
- Delete all appointments and communications on purge (for QA)

### Added 
 
- Sync APIs for Patient medical history
- Sync APIs for Appointments and Communications (for overdue list)
- API for users to request OTPs for login  
- Feature toggles
   - to auto approve users after registration (for QA)
   - to have fixed OTPs (for QA)

## Portal

- Add views for audit logs
- Sort users by fullname 
- Remove user otp message
- Add phone numbers to users index view   
- Order facilities by name

## 2018-08-13-1
## 2018-07-02-1
