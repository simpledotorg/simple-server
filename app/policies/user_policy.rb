class UserPolicy < ApplicationPolicy
  def index?
    user.owner? || user.supervisor? || user.organization_owner?
  end

  def user_belongs_to_admin?
    user.users.include?(record)
  end

  def show?
    index? && user_belongs_to_admin?
  end

  def disable_access?
    show?
  end

  def enable_access?
    show?
  end

  def reset_otp?
    show?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      facilities = @user.facility_groups.flat_map(&:facilities)
      scope.where(facility: facilities)
    end
  end
end
