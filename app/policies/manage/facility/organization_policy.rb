class Manage::Facility::OrganizationPolicy < ApplicationPolicy
  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?([:manage_facilities, :manage_facility_groups])

      organization_ids = organization_ids_for_permission([:manage_facilities, :manage_facility_groups])
      return scope.all if organization_ids.empty?

      scope.where(id: organization_ids)
    end
  end
end
