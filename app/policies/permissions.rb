module Permissions
  ALL_PERMISSIONS = {
    approve_health_workers: {
      slug: :approve_health_workers,
      description: 'Approve health workers',
      resource_priority: %i[facility_group organization global],
      required_permissions: []
    },
    manage_admins: {
      slug: :manage_admins,
      description: 'Manage admins',
      resource_priority: %i[organization global],
      required_permissions: %i[]
    },
    manage_organizations: {
      slug: :manage_organizations,
      description: 'Manage organizations',
      resource_priority: %i[global],
      required_permissions: []
    },
    manage_protocols: {
      slug: :manage_protocols,
      description: 'Manage protocols',
      resource_priority: %i[global],
      required_permissions: []
    },
    manage_facility_groups: {
      slug: :manage_facility_groups,
      description: 'Manage facility groups',
      resource_priority: %i[facility_group organization global],
      required_permissions: []
    },
    manage_facilities: {
      slug: :manage_facilities,
      description: 'Manage facilities',
      resource_priority: %i[facility_group organization global],
      required_permissions: []
    },
    view_cohort_reports: {
      slug: :view_cohort_reports,
      description: 'View cohort reports',
      resource_priority: %i[facility_group organization global],
      required_permissions: []
    },
    view_health_worker_activity: {
      slug: :view_health_worker_activity,
      description: 'View health worker activity',
      resource_priority: %i[facility_group organization global],
      required_permissions: %i[view_cohort_reports]
    },
    view_overdue_list: {
      slug: :view_overdue_list,
      description: 'View overdue list',
      resource_priority: %i[facility_group organization global],
      required_permissions: []
    },
    download_overdue_list: {
      slug: :download_overdue_list,
      description: 'Download overdue list',
      resource_priority: %i[facility_group organization global],
      required_permissions: %i[view_overdue_list]
    },
    view_adherence_follow_up_list: {
      slug: :view_adherence_follow_up_list,
      description: 'View adherence follow up list',
      resource_priority: %i[facility_group organization global],
      required_permissions: []
    },
    download_patient_line_list: {
      slug: :download_patient_line_list,
      description: 'Download patient line list',
      resource_priority: %i[facility_group organization global],
      required_permissions: %i[view_cohort_reports]
    },
    view_sidekiq_ui: {
      slug: :view_sidekiq_ui,
      description: 'View sidekiq UI',
      resource_priority: %i[global],
      required_permissions: []
    },
    view_my_facilities: {
      slug: :view_my_facilities,
      description: 'View My Facilities Dashboard',
      resource_priority: %i[global],
      required_permissions: []
    }
  }.freeze

  ACCESS_LEVELS = [
    { name: :organization_owner,
      description: "Admin for an organization",
      default_permissions: %i[
        manage_facility_groups
        manage_facilities
        approve_health_workers
        view_overdue_list
        view_adherence_follow_up_list
        view_cohort_reports
        manage_admins
        view_health_worker_activity
        download_overdue_list
        download_patient_line_list
      ]
    },
    { name: :counsellor,
      description: "Call center staff",
      default_permissions: %i[
        view_overdue_list
        view_adherence_follow_up_list
      ]
    },
    { name: :supervisor,
      description: "CVHO: Cardiovascular Health Officer",
      default_permissions: %i[
        manage_facilities
        view_overdue_list
        download_overdue_list
        view_adherence_follow_up_list
        approve_health_workers
        view_cohort_reports
        view_health_worker_activity
        download_patient_line_list
        manage_admins
      ]
    },
    { name: :analyst,
      description: "Data analyst",
      default_permissions: %i[
        view_cohort_reports
      ]
    },
    { name: :sts,
      description: "STS: Senior Treatment Supervisor",
      default_permissions: %i[
        manage_facilities
        view_overdue_list
        download_overdue_list
        view_adherence_follow_up_list
        approve_health_workers
        view_health_worker_activity
        download_patient_line_list
        view_cohort_reports
      ]
    },
    { name: :owner,
      description: "Super admin",
      default_permissions: %i[
        manage_organizations
        manage_facility_groups
        manage_facilities
        manage_protocols
        approve_health_workers
        view_overdue_list
        view_adherence_follow_up_list
        view_cohort_reports
        manage_admins
        view_health_worker_activity
        download_overdue_list
        download_patient_line_list
      ]
    },
    { name: :custom,
      description: "Custom",
      default_permissions: %i[]
    }
  ].freeze
end
