# Unreleased
### Added 
### Changed
### Fixed
### Deprecated 
### Removed 
### Security 

# 2018-09-17

### Changed 

- User can belong to multiple facilities
- Sort users by fullname in admin portal
- Remove user otp message from admin portal
- Add phone numbers to users index view   
- Order facilities by name
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
- Views for audit logs
- Feature toggles
   - to auto approve users after registration (for QA)
   - to have fixed OTPs (for QA)

## 2018-08-13
## 2018-07-02