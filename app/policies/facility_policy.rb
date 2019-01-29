class FacilityPolicy < ApplicationPolicy
  def index?
    user.owner? || user.organization_owner? || user.supervisor?
  end

  def show?
    user.owner? || admin_can_access?(:organization_owner) || admin_can_access?(:supervisor)
  end

  def create?
    user.owner? || user.organization_owner?
  end

  def new?
    create?
  end

  def update?
    user.owner? || admin_can_access?(:organization_owner)
  end

  def edit?
    update?
  end

  def destroy?
    user.owner? || admin_can_access?(:organization_owner)
  end

  private

  def admin_can_access?(role)
    user.role == role.to_s && user.facilities.include?(record)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(facility_group: user.facility_groups)
    end
  end
end
