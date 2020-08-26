class CohortReport::OrganizationPolicy < ApplicationPolicy
  def index?
    user.has_permission?(:view_cohort_reports)
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
      organization_ids = organization_ids_for_permission(:view_cohort_reports)
      return scope.all if organization_ids.blank?

      scope.where(id: organization_ids)
    end
  end
end
