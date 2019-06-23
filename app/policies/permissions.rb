module Permissions
  ALL_PERMISSIONS = [
    Permissions::ManagementPermissions::PERMISSIONS,
    Permissions::PHIAccessOnDashboardPermissions::PERMISSIONS,
    Permissions::UserSyncApprovalPermissions::PERMISSIONS
  ].inject({}, &:merge)
end