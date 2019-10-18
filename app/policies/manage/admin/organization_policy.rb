class Manage::Admin::OrganizationPolicy < ApplicationPolicy
  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?(:manage_admins)

      organization_ids = organization_ids_for_permission(:manage_admins)
      return scope.all unless organization_ids.present?

      scope.where(id: organization_ids)
    end
  end
end