class CohortReport::OrganizationPolicy < ApplicationPolicy

  def index?
    user.has_permission?(:view_cohort_reports) || user.has_permission?(:download_patient_line_list)
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?([:view_cohort_reports, :download_patient_line_list])
      organization_ids = organization_ids_for_permission([:view_cohort_reports, :download_patient_line_list])
      return scope.all if organization_ids.blank?

      scope.where(id: organization_ids)
    end
  end
end