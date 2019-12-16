# Unreleased
### Added
### Changed
### Fixed
### Deprecated
### Removed
### Security

# 2019-12-03-1
### Added
### Changed
- Update follow up patients string in en.yml
- Remove bangladesh from manifest for sandbox and production
- Send SMS reminders only to patients who have provided reminder consent
### Fixed
### Deprecated
### Removed
### Security

# 2019-11-28-2
### Added
- Add diabetes model
- Added schema and scaffolding for Diabetes / BloodSugars API
### Changed
- Show the current month for the Analytics dashboards
### Fixed
- Hotfix district analytics views
### Deprecated
### Removed
### Security


# 2019-11-26-1
### Added
- Add support to easily translate API strings using transifex
- Add translations for other languages (hindi, tamil, telegu)
- Support for permissions and updated admin invite UI
### Changed
- Update api docs with address changes
- Re-format the cohort charts
- Update manifest file
### Fixed
### Deprecated
### Removed
### Security
- Bump loofah from 2.2.3 to 2.3.1 (security vulnerability)

# 2019-11-08-1
### Added
- Add a feature toggle for encounters sync
### Changed
- Accept null values for patient address string fields
### Fixed
- 'days_overdue' returns 0 if appointment is not overdue
### Deprecated
### Removed
### Security

# 2019-11-07-1
### Added
- Add zone field to Address model
- Add support for Bangladesh national ID as a business identifier
- Add support for Bangladesh deployments
### Changed
- Update pending CHANGELOGs from the last 9 releases
### Fixed
### Deprecated
### Removed
- Remove current quarter whatsapp graphic download link
### Security

# 2019-11-04-1
### Added
- Add trailing slashes to manifest URLs
- Delete Observations and Encounters when purging data on QA
- dates_for_periods helper optionally honors the current period (for progress tab)
### Removed
- Remove automerge github action
### Fixed
### Deprecated
### Removed
### Security

# 2019-10-31-1
### Added
- Host a manifest file to keep country-specific info
- Add data migration for existing BloodPressures to have Encounters
- Use batch API when exporting patients to CSV
- Describe the seed generation rake task in README
- Update the HELP screen (new SVGs and copy changes)
### Changed
- Replace the unique patients graph with follow up patients for progress tab
- Stagger nightly sidekiq jobs
### Fixed
### Deprecated
### Removed
- Remove role, organization_id from the user response payload
- Remove current quarter from analytics
- Remove all usage of SMS reminder Bot User
### Security

# 2019-10-24-4
### Added
- Enable patient line list
- Period persistence across dashboard views
- Add the Encounters API (turned off)
- Add Bengali help screen template
- I18n progress tab bengali
- Update seed generation scripts
- Use tablesort to sort analytics table
- De-duplicate gem dependencies
- Report in India time 
- Add i18n login api messages for Bangla
- Add messages to audit_log data jobs to indicate progress
### Changed
- Use timestamps instead of dates
- Update Time parsing to use app timezone
### Fixed
### Deprecated
### Removed
- Remove the foreign-key constraint between encounters and patients
### Security

# 2019-10-09-1
### Added
- Add reminder_consent to patient model and APIs
### Changed
- Update sidekiq instance DNS
- Update copy in monthly cohort reports
### Fixed
### Deprecated
### Removed
### Security

# 2019-10-08-1
### Added
- Patient line list download
- Add a task to backfill user_ids for prescription_drugs and medical_histories using existing audit logs
- Add a task to export audit logs to files
### Changed
- Update the cohort report script to use CohortAnalyticsQuery
- Update monthly cohort calculation
- Move audit logs from the DB to a file
### Fixed
### Deprecated
### Removed
- Remove audit log search from dashboard
### Security

# 2019-10-03-1
### Added
- Alias master_users to users
- Add feature specs for Protocol screens
- Add feature specs for Adherence list screens
- Time travel during sandbox data generation
### Changed
- Updating Sidekiq box IP post reboot
### Fixed
- Fixed typo in cohort description
### Deprecated
### Removed
### Security

# 2019-10-01-1
### Added
-  Support switching between monthly and quarterly cohort charts 
### Changed
### Fixed
### Deprecated
### Removed
### Security

# 2019-09-16-1
### Added
- Add updated at timestamp to progress tab
### Changed
### Fixed
### Deprecated
### Removed
### Security

# 2019-09-13-1
### Added
- Send user approval emails using sidekiq
- Add instrumentation for merge_if_valid
### Changed
- Update devise gem
### Fixed
### Deprecated
### Removed
### Security

# 2019-09-12-1
### Added
- Add custom instrumentation to measure time taken to merge records
- Purge Patient Business Identifiers on QA
- Feature toggle downloads for analytics > facilities page
- Add a script for generating seed data; Adding  factory_bot, faker and Timecop to production group
### Changed
- Allow 'Reset PIN' reason for users with requested access
### Fixed
### Deprecated
### Removed
- Remove obsolete rake tasks
- Removed FontAwesome symbols for greater/equal and less than in the WhatsApp graphics.
### Security

# 2019-09-09-1
### Added
- Allow max limit to be set per controller
### Changed
### Fixed
### Deprecated
### Removed
### Security

# 2019-09-04-2
### Added
- Fix feature toggle to enable downloading dashboard snapshots
### Changed
### Fixed
### Deprecated
### Removed
### Security

# 2019-09-04-1
### Added
- Add managed SQL views to the repo
### Changed
- Change 'enrollment' to 'registration' for consistency
- Order the dashboard sync approval users by updated_at
### Fixed
- Allow owners to download whatsapp graphics as well
### Deprecated
### Removed
### Security

# 2019-08-12-1
### Added
### Changed
- Generalize move user data task to accept destination facility
- View specs: Page object refactoring
### Fixed
### Deprecated
### Removed
### Security

# 2019-08-08-1
### Added
- Add support for downloading Dashsboard Snapshots
- Add task to move data incorrectly recorded by a user to the correct facility
- Add Recent BP logs to facility and user views
### Changed
- Paginate the user list on dashboard and user index
- Return 403 for users not allowed to sync
- Styling changes for user details page
- Swapped out the new Hindi help video in the HELP section.
### Fixed
- Only show analytics for registered patients in cohort reports for a facility
- Handle unsuccessful responses for exotel phone number info api calls
- Fixed incorrect quarters data being shown in the graphics header
- Fix analyst permissions
- Fix consistent time zones in analytics and user controllers
### Deprecated
- Remove support for V1 api
### Removed
### Security

# 2019-07-30-1
### Added
- Added caching for analytics dashboard
- Auto whiltelist patient phone numbers
- Periodically update patient phone numbers
### Changed
- Moved Download Overdue List to the top of the screen
### Fixed
- Check if user.logged_in_at is present before localizing time
- Removing the last BP for a patient should decrement follow-up count
- Count patients registered without a BP as registered patients
### Deprecated
### Removed
### Security


# 2019-07-25-1
### Added
### Changed
- Better formatting of the dashboard for mobile
### Fixed
- Invisible hamburger menu icon on mobile dashboard
### Deprecated
### Removed
### Security

# 2019-07-23-1
### Added
- Complete UI refresh
- Replace device_created_at with recorded_at in the dashboard queries
- Added tooltips to cohort reports screen
- Set patients#index as root route for counsellors 
- Add a confirmation step for deployment tasks (production & staging)
- Add docs on how to generate an ERD
### Changed
- Skip sending emails in QA env for reset_password flow
- Improve facility upload error messages
- Moved cohort reporting to a rake task
- Make the User dashboard viewing policy respect our actual policy 
### Fixed
- Show dashboard data only for facilities under the current organization
- Uncontrolled patient percent in the cohort chart
### Deprecated
### Removed
### Security

# 2019-07-08-1
### Added
- Add quarterly cohort charts to district and facility dashboards (#463)
- Add audit_logs to User (master_users) model (#456)
- Sharing anonymised data dump
- Simple Dashboard V2 (District + Facility View) (#447)
- Bulk upload facilities V1
### Changed
- Updated staging domain name
- Replace before :all with before :each to ensure db is cleaned up afte…
- Move user authentication to master user
### Fixed
- Only display flash messages of type String in the login page (#455)
- Avoid sending emails during registration when auto approve is enabled (…
- Update swagger.json + handle user registration errors better (#458)
- Fix issues with user registration and login (#454)
- Prevent n+1 queries for facility and patient sync (#453)
### Deprecated
### Removed
### Security

# 2019-06-21-1
### Added
- Add a high-priority queue for time-sensitive jobs like sms reminders
- Legal footer to the dashboard
### Changed
- Update the staging public IP for cap
### Fixed
### Deprecated
### Removed
### Security

# 2019-06-12-1
### Added
- Add support for Retroactive Data Entry
### Changed
- Optimize the initial data migration queries for Retroactive Data Entry
- Speed up tests (~35% on a single thread)
### Fixed
### Deprecated
### Removed
### Security

# 2019-06-05-1
### Added
- Add non-breaking Sync API changes without frequent version bumps
- Use capistrano to copy sandbox DB to local dev
- Use Google Analytics in production
- Create master users model
### Changed
### Fixed
- Fix patient not existing on an appointment when trying to notify them
- Show labels as 'Last 90 days'
### Deprecated
### Removed
### Security

# 2019-05-30-1
### Added
- Add Twilio sub-account support
- Add percentage symbol to BP header and values in Dashboard
- Show enrollment date in overdue list download 
### Changed
### Fixed
- Fixing formatting issues in overdue list dashboard view
### Deprecated
### Removed
### Security

# 2019-05-25-1
### Added
### Changed
### Fixed
- HOTFIX: Authorization policy for district analytics dashboard
### Deprecated
### Removed
### Security

# 2019-05-24-1
### Added
- Display facilities by district instead of by facility group
- View Caching for Districts
### Changed
- Update the demo DNS for capistrano
- Split analytics cache warmup jobs for facilities
### Fixed
- Cache facilities and facility_groups view cache by ID rather than slug
- Fix warmup for quarterly analytics
- Prevent BotUser initialization when migrations are running
### Deprecated
### Removed
- Delete key before running district analytics warmup
- Remove User association from CallLogs in favour of caller_phone_number
### Security

# 2019-05-15-1
### Added
### Changed
### Fixed
- Fix dashboard caching
### Deprecated
### Removed
### Security

# 2019-05-14-1
### Added
- Schedule automatic SMS reminders (Feature toggled off)
- Show enrollment date for overdue patients
- Display last interaction result (if present)
- Add caller_phone_number to `CallLog`
- Data migration to move User phone numbers to caller_phone_numbers in `CallLogs`
- BP passport video to help api html
### Changed
- Stub V1 & V2 Communications API to return empty responses
- Remove User authorization during an exotel session for phone masking
- Make user_id optional in `CallLog`
### Fixed
- Set the ENV path for the `whenever` gem so it can pick up the rbenv ruby shim
### Deprecated
- Deprecate the unused `Communication` V3 API
### Removed
- Remove `communication_result` from `Communication` resource
### Security

# 2019-05-03-1
### Added 
### Changed
### Fixed
- Fix `appointment type` syncing issues with API v1 and v2. 
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
- Adherence tab: show enrollment date for patients without BP
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
- Adding patient record creation date as enrollment date for adherence tab
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
- Adding patient record creation date as enrollment date for adherence tab
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
