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
        scope.all.select do |admin|
          !admin.owner? && Admin.have_common_organization(user, admin)
        end
      else
        scope.none
      end
    end
  end
end
