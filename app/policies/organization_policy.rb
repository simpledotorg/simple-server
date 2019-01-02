class OrganizationPolicy < ApplicationPolicy
  def index?
    user.owner? || user.organization_owner?
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
      scope.where(id: @user.organizations.map(&:id))
    end
  end
end