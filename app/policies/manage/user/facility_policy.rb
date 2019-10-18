class Manage::User::FacilityPolicy < ApplicationPolicy
  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?(:approve_health_workers)

      facility_ids = facility_ids_for_permission(:approve_health_workers)
      return scope.all if facility_ids.blank?

      scope.where(id: facility_ids)
    end
  end
end
