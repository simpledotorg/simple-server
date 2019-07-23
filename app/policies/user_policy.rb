class UserPolicy < ApplicationPolicy
  def index?
    user.has_role?(:owner, :organization_owner, :supervisor)
  end

  def show?
    user.owner? || (user.has_role?(:organization_owner, :supervisor) && belongs_to_admin?)
  end

  def new?
  end

  def create?
    new?
  end

  def update?
    show?
  end

  def edit?
    update?
  end

  def destroy?
  end

  def disable_access?
    update?
  end

  def enable_access?
    update?
  end

  def reset_otp?
    update?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if @user.owner?
        scope.all
      elsif @user.has_role?(:analyst, :counsellor)
        scope.none
      else
        scope.where(id: user.users)
      end
    end
  end

  private

  def belongs_to_admin?
    user.users.include?(record)
  end
end
