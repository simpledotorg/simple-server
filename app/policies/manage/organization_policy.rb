class Manage::OrganizationPolicy < ApplicationPolicy
  def index?
    user.user_permissions
      .where(permission_slug: [:manage_organizations])
      .present?
  end

  def show?
    user_has_any_permissions?(
      [:manage_organizations, nil],
      [:manage_organizations, record]
    )
  end

  def create?
    user_has_any_permissions?(:manage_organizations)
  end

  def new?
    create?
  end

  def update?
    user_has_any_permissions?(
      [:manage_organizations, nil],
      [:manage_organizations, record]
    )
  end

  def edit?
    update?
  end

  def destroy?
    destroyable? && user_has_any_permissions?(:manage_organizations)
  end

  private

  def destroyable?
    record.facility_groups.none?
  end

  class Scope < Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user.has_permission?(:manage_organizations)

      organization_ids = organization_ids_for_permission(:manage_organizations)
      return scope.all if organization_ids.empty?

      scope.where(id: organization_ids)
    end
  end
end
