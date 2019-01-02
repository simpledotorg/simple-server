class FacilityPolicy < ApplicationPolicy
  def index?
    user.owner? || user.organization_owner? || user.supervisor?
  end

  def show?
    index?
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
