# Unreleased
### Added 
### Changed
### Fixed
### Deprecated 
### Removed 
### Security 

# 2018-12-21-1

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
- Prioritise current facility sync for Patients, BPs, Drugs, and Appointments
- API schema now has process_token instead of processed_since
- Make diagnosed with hypertension a required field for medical history
- Update cancel reasons in appointments
  - Add 3 new reasons to v2, exclude them from v1, and coerce accordingly
  - Updation of cancelled appointments is disallowed in v1
- Restrict sycning of records to a users facility group
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
