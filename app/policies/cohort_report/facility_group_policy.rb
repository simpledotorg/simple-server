class CohortReport::FacilityGroupPolicy < ApplicationPolicy
  def patient_list?
    user_has_any_permissions?(
      [:download_patient_line_list, nil],
      [:download_patient_line_list, record.organization],
      [:download_patient_line_list, record]
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
      return scope.none unless user.has_permission?(:view_cohort_reports)
      facility_group_ids = facility_group_ids_for_permission(:view_cohort_reports)
      return scope.all if facility_group_ids.blank?

      scope.where(id: facility_group_ids)
    end
  end
end
