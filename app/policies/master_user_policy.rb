class MasterUserPolicy < ApplicationPolicy
  def index?
    user.owner? || user.supervisor? || user.organization_owner?
  end

  def user_belongs_to_admin?
    user.users.include?(record)
  end

  def show?
    user.owner? || user_belongs_to_admin?
  end

  def update?
    show?
  end

  def edit?
    update?
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
      # facilities = @user.facility_groups.flat_map(&:facilities)
      # scope.where(facility: facilities)
      scope.all
    end
  end
end
