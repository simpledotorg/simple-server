class CohortReport::FacilityPolicy < ApplicationPolicy

  def view_health_worker_activity?
    user_has_any_permissions?(
      [:view_health_worker_activity, nil],
      [:view_health_worker_activity, record.organization],
      [:view_health_worker_activity, record.facility_group],
      )
  end

  def whatsapp_graphics?
    show?
  end

  def patient_list?
    user_has_any_permissions?(
      [:download_patient_line_list, nil],
      [:download_patient_line_list, record.organization],
      [:download_patient_line_list, record.facility_group],
      )
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?(:view_cohort_reports)

      facility_ids = facility_ids_for_permission(:view_cohort_reports)
      return scope.all if facility_ids.blank?

      scope.where(id: facility_ids)
    end
  end
end
