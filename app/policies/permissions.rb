module Permissions
  ALL_PERMISSIONS = {
    approve_health_workers: {
      slug: :approve_health_workers,
      description: 'Approve health workers',
      resource_types: [:global, :organization, :facility_group]
    },
    manage_admins: {
      slug: :manage_admins,
      description: 'Manage Admins',
      resource_types: [:global, :organization, :facility_group]
    },
    manage_organizations: {
      slug: :manage_organizations,
      description: 'Manage organizations',
      resource_types: [:global]
    },
    manage_protocols: {
      slug: :manage_protocols,
      description: 'Manage protocols',
      resource_types: [:global]
    },
    manage_facility_groups: {
      slug: :manage_facility_groups,
      description: 'Manage facility groups',
      resource_types: [:global, :organization]
    },
    manage_facilities: {
      slug: :manage_facilities,
      description: 'Manage facilities',
      resource_types: [:global, :organization, :facility_group]
    },
    view_cohort_reports: {
      slug: :view_cohort_reports,
      description: 'View cohort reports',
      resource_types: [:global, :organization, :facility_group],
    },
    view_health_worker_activity: {
      slug: :view_health_worker_activity,
      description: 'View health worker activity',
      resource_types: [:global, :organization, :facility_group],
    },
    view_overdue_list: {
      slug: :view_overdue_list,
      description: 'View overdue list',
      resource_types: [:global, :organization, :facility_group]
    },
    download_overdue_list: {
      slug: :download_overdue_list,
      description: 'Download overdue list',
      resource_types: [:global, :organization, :facility_group]
    },
    view_adherence_follow_up_list: {
      slug: :view_adherence_follow_up_list,
      description: 'View adherence follow up list',
      resource_types: [:global, :organization, :facility_group]
    }
  }

  ACCESS_LEVELS = [
    { name: :counsellor,
      description: "Call center staff (access to PHI)",
      resource_type: :facility_group,
      default_permissions: [
        :view_overdue_list,
        :view_adherence_follow_up_list
      ]
    },
    { name: :organization_owner,
      description: "Admin for an organization",
      resource_type: :organization,
      default_permissions: [
        :manage_facility_groups,
        :view_overdue_list,
        :view_adherence_follow_up_list,
        :approve_health_workers,
        :manage_admins
      ]
    },
    { name: :analyst,
      description: "Data analyst",
      resource_type: :facility_group,
      default_permissions: [
        :view_cohort_reports
      ]
    },
    { name: :supervisor,
      description: "CVHO: Cardiovascular Health Officer (access to PHI)",
      resource_type: :facility_group,
      default_permissions: [
        :manage_facilities,
        :view_overdue_list,
        :download_overdue_list,
        :view_adherence_follow_up_list,
        :approve_health_workers,
        :view_cohort_reports
      ]
    },
    { name: :sts,
      description: "STS: Senior Treatment Supervisor (access to PHI)",
      resource_type: :facility_group,
      default_permissions: [
        :manage_facilities,
        :view_overdue_list,
        :download_overdue_list,
        :view_adherence_follow_up_list,
        :approve_health_workers
      ]
    },
    { name: :owner,
      description: "Super admin",
      resource_type: :global,
      default_permissions: [
        :manage_organizations,
        :manage_protocols,
        :approve_health_workers,
        :view_overdue_list,
        :view_adherence_follow_up_list,
        :manage_admins
      ]
    },
    { name: :custom,
      description: "Custom",
      default_permissions: []
    }
  ]
end