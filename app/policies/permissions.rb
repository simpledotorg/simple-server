module Permissions
  ALL_PERMISSIONS = [
    ManagementPermissions::PERMISSIONS,
    PHIAccessOnDashboardPermissions::PERMISSIONS,
    UserManagementPermissions::PERMISSIONS
  ].inject({}, &:merge)

  def self.select_permissions(query)
    ALL_PERMISSIONS.select()
  end
end