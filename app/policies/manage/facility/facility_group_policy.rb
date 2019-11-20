class Manage::Facility::FacilityGroupPolicy < ApplicationPolicy
  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?(:manage_facilities)

      facility_group_ids = facility_group_ids_for_permission(:manage_facilities)
      facility_group_ids = facility_group_ids_for_permission(:manage_facilities)
      return scope.all if facility_group_ids.empty?

      scope.where(id: facility_group_ids)
    end
  end
end
