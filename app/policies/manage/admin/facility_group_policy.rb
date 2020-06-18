class Manage::Admin::FacilityGroupPolicy < ApplicationPolicy
  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?(:manage_admins)

      facility_group_ids = facility_group_ids_for_permission(:manage_admins)
      return scope.all unless facility_group_ids.present?

      scope.where(id: facility_group_ids)
    end
  end
end
