class CohortReport::FacilityPolicy < ApplicationPolicy
  def show?
    user_has_any_permissions?(
      [:view_cohort_reports, nil],
      [:view_cohort_reports, record.organization],
      [:view_cohort_reports, record.facility_group]
    )
  end

  def view_health_worker_activity?
    user_has_any_permissions?(
      [:view_health_worker_activity, nil],
      [:view_health_worker_activity, record.organization],
      [:view_health_worker_activity, record.facility_group]
    )
  end

  def whatsapp_graphics?
    show?
  end

  def patient_list?
    user_has_any_permissions?(
      [:download_patient_line_list, nil],
      [:download_patient_line_list, record.organization],
      [:download_patient_line_list, record.facility_group]
    )
  end

  def patient_list_with_history?
    patient_list?
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      super
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?([:view_cohort_reports, :download_patient_line_list])

      facility_ids = facility_ids_for_permission([:view_cohort_reports, :download_patient_line_list])
      return scope.all if facility_ids.blank?

      scope.where(id: facility_ids)
    end
  end
end
