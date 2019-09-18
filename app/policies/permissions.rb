module Permissions
  ALL_PERMISSIONS = [
    ManagementPermissions::PERMISSIONS,
    PHIAccessOnDashboardPermissions::PERMISSIONS,
    UserManagementPermissions::PERMISSIONS
  ].inject({}, &:merge)

  ACCESS_LEVELS = [
    { name: :call_center_staff,
      description: "Call center staff (access to PHI)",
      default_permissions: [
        :can_manage_a_facility_group,
        :can_access_appointment_information_for_facility_group,
        :can_access_patient_information_for_facility_group
      ]
    },
    { name: :cvho,
      description: "CVHO: Cardiovascular Health Officer (access to PHI)",
      default_permissions: [
        :can_manage_a_facility_group,
        :can_access_appointment_information_for_facility_group,
        :can_access_patient_information_for_facility_group,
        :can_manage_users_for_facility_group
      ]
    },
    { name: :data_analyst,
      description: "Data analyst (anonymized data only)",
      default_permissions: [
        :can_manage_a_facility_group
      ]
    },
    { name: :sts,
      description: "STS: Senior Treatment Supervisor (access to PHI)",
      default_permissions: [
        :can_manage_a_facility_group,
        :can_access_appointment_information_for_facility_group,
        :can_access_patient_information_for_facility_group,
        :can_manage_users_for_facility_group
      ]
    },
    { name: :super_admin,
      description: "Super admin",
      default_permissions: [
        :can_manage_all_organizations,
        :can_manage_all_protocols,
        :can_manage_audit_logs,
        :can_manage_all_users
      ]
    },
    { name: :custom,
      description: "Custom",
      default_permissions: []
    }
  ]

  def self.select_permissions(query)
    ALL_PERMISSIONS.select()
  end
end