module Permissions::PHIAccessOnDashboardPermissions
  PATIENT_PERMISSIONS = {
    can_access_patient_information_for_all_organizations: {
      type: :global,
      slug: :can_access_patient_information_for_organization,
    },
    can_access_patient_information_for_organization: {
      type: :resource,
      slug: :can_access_patient_information_for_organization,
      resource_type: 'Organization'
    },
    can_access_patient_information_for_facility_group: {
      type: :resource,
      slug: :can_access_patient_information_for_facility_group,
      resource_type: 'FacilityGroup'
    },
    can_access_patient_information_for_facility: {
      type: :resource,
      slug: :can_access_patient_information_for_facility,
      resource_type: 'Facility'
    }
  }

  APPOINTMENT_PERMISSIONS = {
    can_access_appointment_information_for_all_organizations: {
      type: :global,
      slug: :can_access_appointment_information_for_organization,
    },
    can_access_appointment_information_for_organization: {
      type: :resource,
      slug: :can_access_appointment_information_for_organization,
      resource_type: 'Organization'
    },
    can_access_appointment_information_for_facility_group: {
      type: :resource,
      slug: :can_access_appointment_information_for_facility_group,
      resource_type: 'FacilityGroup'
    },
    can_access_appointment_information_for_facility: {
      type: :resource,
      slug: :can_access_appointment_information_for_facility,
      resource_type: 'Facility'
    }
  }

  OVERDUE_LIST_DOWNLOAD = {
    can_download_overdue_list_for_all_organizations: {
      type: :global,
      slug: :can_download_overdue_list_for_all_organizations,
    },
    can_download_overdue_list_for_organization: {
      type: :resource,
      slug: :can_download_overdue_list_for_organization,
      resource_type: 'Organization'
    },
    can_download_overdue_list_for_facility_group: {
      type: :resource,
      slug: :can_download_overdue_list_for_facility_group,
      resource_type: 'FacilityGroup'
    },
    can_download_overdue_list_for_facility: {
      type: :resource,
      slug: :can_download_overdue_list_for_facility,
      resource_type: 'Facility'
    }
  }

  PERMISSIONS = [PATIENT_PERMISSIONS, APPOINTMENT_PERMISSIONS, OVERDUE_LIST_DOWNLOAD].inject({}, &:merge)
end