module ManagementPermissions
  PERMISSIONS = {
    can_manage_all_organizations: {
      type: :global,
      slug: :can_manage_all_organizations
    },
    can_manage_an_organization: {
      type: :resource,
      slug: :can_manage_an_organization,
      resource_type: 'Organization'
    },
    can_manage_a_facility_group: {
      type: :resource,
      slug: :can_manage_a_facility_group,
      resource_type: 'FacilityGroup'
    },
    can_manage_all_protocols: {
      type: :global,
      slug: :can_manage_all_protocols
    },
    can_manage_audit_logs: {
      type: :global,
      slug: :can_manage_audit_logs
    }
  }
end