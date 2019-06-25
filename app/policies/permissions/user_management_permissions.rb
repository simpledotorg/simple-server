module Permissions::UserManagementPermissions

  PERMISSIONS = {
    can_manage_users_for_facility_group: {
      type: :resource,
      slug: :can_manage_users_for_facility_group,
      resource_type: 'FacilityGroup'
    },
    can_manage_users_for_organization: {
      type: :resource,
      slug: :can_manage_users_for_organization,
      resource_type: 'Organization'
    },
    can_manage_all_users: {
      type: :global,
      slug: :can_manage_all_users
    }
  }
end