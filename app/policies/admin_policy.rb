class AdminPolicy < ApplicationPolicy
  def index?
    user.owner? || user.organization_owner?
  end

  def show?
    user.owner? || user.organization_owner?
  end

  def create?
    user.owner? || user.organization_owner?
  end

  def new?
    create?
  end

  def update?
    user.owner? || user.organization_owner?
  end

  def edit?
    update?
  end

  def destroy?
    user.owner?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.owner?
        scope.all
      elsif user.organization_owner?
        organization_admin_ids = AdminAccessControl.where(access_controllable: user.organizations).pluck(:admin_id)
        facility_group_admin_ids = AdminAccessControl.where(access_controllable: user.facility_groups).pluck(:admin_id)
        scope.where(id: [organization_admin_ids + facility_group_admin_ids].uniq)
      else
        scope.none
      end
    end
  end
end
