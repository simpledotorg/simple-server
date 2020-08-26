class Manage::Admin::FacilityPolicy < ApplicationPolicy
  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      super
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?(:manage_admins)

      facility_ids = facility_ids_for_permission(:manage_admins)
      return scope.all unless facility_ids.present?

      scope.where(id: facility_ids)
    end
  end
end
