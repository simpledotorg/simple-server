class FacilityGroupPolicy < ApplicationPolicy
  def index?
    user.owner? || user.organization_owner?
  end

  def show?
    user.owner? || admin_can_access?(:organization_owner)
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
    destroyable? && (user.owner? || admin_can_access?(:organization_owner))
  end

  private

  def destroyable?
    record.facilities.none? && record.patients.none? && record.blood_pressures.none?
  end

  def admin_can_access?(role)
    user.role == role.to_s && user.facility_groups.include?(record)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(id: @user.facility_groups.map(&:id))
    end
  end
end
