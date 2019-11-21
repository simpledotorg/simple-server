class Manage::Facility::FacilityGroupPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: [:manage_facility_groups])
      .present?
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?([:manage_facilities, :manage_facility_groups])

      facility_group_ids = facility_group_ids_for_permission([:manage_facilities, :manage_facility_groups])
      return scope.all if facility_group_ids.empty?

      scope.where(id: facility_group_ids)
    end
  end
end
