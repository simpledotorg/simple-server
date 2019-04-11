class OrganizationPolicy < ApplicationPolicy
  def index?
    user.owner? || user.organization_owner?
  end

  def show?
    user.owner? || admin_can_access?(:organization_owner)
  end

  def update?
    show?
  end

  def edit?
    update?
  end

  def destroy?
    destroyable? && user.owner?
  end

  private

  def destroyable?
    record.facility_groups.none?
  end

  def admin_can_access?(role)
    user.role == role.to_s && user.organizations.include?(record)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(id: @user.organizations.map(&:id))
    end
  end
end
