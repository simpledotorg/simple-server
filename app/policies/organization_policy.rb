class OrganizationPolicy < ApplicationPolicy
  def index?
    user_has_any_permissions?(:can_manage_all_organizations)
  end

  def show?
    user_has_any_permissions?(
      :can_manage_all_organizations,
      [:can_manage_an_organization, record]
    )
  end

  def create?
    user_has_any_permissions?(:can_manage_all_organizations)
  end

  def new?
    create?
  end

  def update?
    show?
  end

  def edit?
    update?
  end

  def destroy?
    destroyable? && user_has_any_permissions?(:can_manage_all_organizations)
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
      if user.has_permission?(:can_manage_all_organizations)
        scope.all
      elsif user.has_permission?(:can_manage_an_organization)
        scope.where(id: resources_for_permission(:can_manage_an_organization).map(&:id))
      else
        scope.none
      end
    end
  end
end
