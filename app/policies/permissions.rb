module Permissions
  ALL_PERMISSIONS = [
    Permissions::ManagementPermissions::PERMISSIONS,
    Permissions::PHIAccessOnDashboardPermissions::PERMISSIONS,
    Permissions::UserManagementPermissions::PERMISSIONS
  ].inject({}, &:merge)
end