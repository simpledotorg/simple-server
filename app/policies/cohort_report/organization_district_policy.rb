class CohortReport::OrganizationDistrictPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: [:manage_organizations, :manage_facility_groups])
      .present?
  end

  def show?
    user.has_permission?(:view_cohort_reports) || user_has_any_permissions?(
      [:manage_organizations, nil],
      [:manage_facility_groups, record.organization],
    )
  end

  def share_anonymized_data?
    user_has_any_permissions?(:manage_organizations)
  end

  def whatsapp_graphics?
    show?
  end

  def patient_list?
    user_has_any_permissions?(
      [:download_patient_line_list, nil],
      [:download_patient_line_list, record.organization])
  end
end
