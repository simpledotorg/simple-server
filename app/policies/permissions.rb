module Permissions
  ALL_PERMISSIONS = {
    approve_health_workers_for_all_organizations: {
      type: :global,
      slug: :approve_health_workers_for_all_organizations,
      description: 'Approve all health workers'
    },
    approve_health_workers_for_organization: {
      type: :resource,
      slug: :approve_health_workers_for_organization,
      resource_type: 'Organization',
      description: 'Approve health workers for an organization'
    },
    approve_health_workers_for_facility_group: {
      type: :resource,
      slug: :approve_health_workers_for_facility_group,
      resource_type: 'FacilityGroup',
      description: 'Approve health workers for an facility group'
    },
    manage_admins_for_all_organizations: {
      type: :global,
      slug: :manage_admins_for_all_organizations,
      description: 'Manage admins for all organizations'
    },
    manage_admins_for_organization: {
      type: :resource,
      slug: :manage_admins_for_organization,
      resource_type: 'Organization',
      description: 'Manage admins for an organization'
    },
    manage_organizations: {
      type: :global,
      slug: :manage_organizations,
      description: 'Manage organizations'
    },
    manage_protocols: {
      type: :global,
      slug: :manage_protocols,
      description: 'Manage protocols'
    },
    manage_facility_groups_for_organization: {
      type: :resource,
      slug: :manage_facility_groups_for_organization,
      resource_type: 'Organization',
      description: 'Manage facility groups for an organization'
    },
    manage_facilities_for_facility_group: {
      type: :resource,
      slug: :manage_facilities_for_facility_group,
      resource_type: 'FacilityGroup',
      description: 'Manage facilities for a facility group'
    },
    view_cohort_reports_for_organization: {
      type: :resource,
      slug: :view_cohort_reports_for_organization,
      resource_type: 'Organization',
      description: 'View cohort reports for an organization'
    },
    view_cohort_reports_for_facility_group: {
      type: :resource,
      slug: :view_cohort_reports_for_facility_group,
      resource_type: 'FacilityGroup',
      description: 'View cohort reports for a facility group'
    },
    view_health_worker_activity_for_organization: {
      type: :resource,
      slug: :view_health_worker_activity_for_organization,
      resource_type: 'Organization',
      description: 'View health worker activity for organization'
    },
    view_health_worker_activity_for_facility_group: {
      type: :resource,
      slug: :view_health_worker_activity_for_facility_group,
      resource_type: 'FacilityGroup',
      description: 'View health worker activity for facility group'
    },
    view_overdue_list_for_all_organizations: {
      type: :global,
      slug: :view_overdue_list_for_all_organizations,
      description: 'View overdue list for all organizations'
    },
    view_overdue_list_for_organization: {
      type: :resource,
      slug: :view_overdue_list_for_organization,
      resource_type: 'Organization',
      description: 'View overdue list for organization'
    },
    view_overdue_list_for_facility_group: {
      type: :resource,
      slug: :view_overdue_list_for_facility_group,
      resource_type: 'FacilityGroup',
      description: 'View overdue list for a facility group'
    },
    download_overdue_list_for_organization: {
      type: :resource,
      slug: :download_overdue_list_for_organization,
      resource_type: 'Organization',
      description: 'View overdue list for organization'
    },
    download_overdue_list_for_facility_group: {
      type: :resource,
      slug: :download_overdue_list_for_facility_group,
      resource_type: 'FacilityGroup',
      description: 'View overdue list for a facility group'
    },
    view_adherence_follow_up_list_for_all_organizations: {
      type: :global,
      slug: :view_adherence_follow_up_list_for_all_organizations,
      description: 'View adherence follow up list for all organizations'
    },
    view_adherence_follow_up_list_for_organization: {
      type: :resource,
      slug: :view_adherence_follow_up_list_for_organization,
      resource_type: 'Organization',
      description: 'View adherence follow up list for organization'
    },
    view_adherence_follow_up_list_for_facility_group: {
      type: :resource,
      slug: :view_adherence_follow_up_list_for_facility_group,
      resource_type: 'FacilityGroup',
      description: 'View adherence follow up list for a facility group'
    },
    view_audit_logs: {
      type: :global,
      slug: :view_audit_logs,
      description: 'View audit logs'
    },
  }

  ACCESS_LEVELS = [
    { name: :counsellor,
      description: "Call center staff (access to PHI)",
      default_permissions: [
        :view_overdue_list_for_facility_group,
        :view_adherence_follow_up_list_for_facility_group
      ]
    },
    { name: :organization_owner,
      description: "Admin for an organization",
      default_permissions: [
        :manage_facility_groups_for_organization,
        :view_overdue_list_for_organization,
        :view_adherence_follow_up_list_for_organization,
        :approve_health_workers_for_organization,
        :manage_admins_for_organization
      ]
    },
    { name: :analyst,
      description: "Data analyst",
      default_permissions: [
        :view_cohort_reports_for_facility_group
      ]
    },
    { name: :supervisor,
      description: "CVHO: Cardiovascular Health Officer (access to PHI)",
      default_permissions: [
        :manage_facilities_for_facility_group,
        :view_overdue_list_for_facility_group,
        :download_overdue_list_for_facility_group,
        :view_adherence_follow_up_list_for_facility_group,
        :approve_health_workers_for_facility_group
      ]
    },
    { name: :sts,
      description: "STS: Senior Treatment Supervisor (access to PHI)",
      default_permissions: [
        :manage_facilities_for_facility_group,
        :view_overdue_list_for_facility_group,
        :download_overdue_list_for_facility_group,
        :view_adherence_follow_up_list_for_facility_group,
        :approve_health_workers_for_facility_group
      ]
    },
    { name: :owner,
      description: "Super admin",
      default_permissions: [
        :manage_organizations,
        :manage_protocols,
        :view_audit_logs,
        :approve_health_workers_for_all_organizations,
        :view_overdue_list_for_all_organizations,
        :view_adherence_follow_up_list_for_all_organizations,
        :manage_admins_for_all_organizations
      ]
    },
    { name: :custom,
      description: "Custom",
      default_permissions: []
    }
  ]
end