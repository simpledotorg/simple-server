# Unreleased
### Added 
### Changed
### Fixed
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
