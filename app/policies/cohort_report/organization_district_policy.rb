class CohortReport::OrganizationDistrictPolicy < ApplicationPolicy
  def show?
    view_cohort_reports? || patient_list?
  end

  def view_cohort_reports?
    user_has_any_permissions?(
      [:view_cohort_reports, nil],
      [:view_cohort_reports, record.organization]
    )
  end

  def share_anonymized_data?
    user_has_any_permissions?(:manage_organizations)
  end

  def whatsapp_graphics?
    view_cohort_reports?
  end

  def patient_list?
    user.user_permissions.where(permission_slug: :download_patient_line_list).present?
  end
end
