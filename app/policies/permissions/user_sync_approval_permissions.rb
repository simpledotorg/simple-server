module Permissions::UserSyncApprovalPermissions

  PERMISSIONS = {
    can_approve_users_for_facility_group: {
      type: :resource,
      slug: :can_approve_users_for_facility_group,
      resource_type: 'FacilityGroup'
    },
    can_approve_users_for_organization: {
      type: :resource,
      slug: :can_approve_users_for_organization,
      resource_type: 'Organization'
    },
    can_approve_all_users: {
      type: :resource,
      slug: :can_approve_all_users,
      resource_type: 'Organization'
    }
  }
end