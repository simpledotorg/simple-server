class DistrictPolicy < ApplicationPolicy
  def index?
    user.owner? || user.organization_owner?
  end

  def show?
    user.owner? || [:organization_owner, :supervisor, :analyst].map { |role| admin_can_access?(role) }.any?
  end

  def graphics?
    show?
  end

  private

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
