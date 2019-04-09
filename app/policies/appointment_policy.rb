class AppointmentPolicy < ApplicationPolicy
  def index?
    user.owner? || user.supervisor? || user.counsellor?
  end

  def update?
    index?
  end

  def download?
    user.owner? || user.supervisor? && user.organizations.include?("IHMI")
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(facility: @user.facilities)
    end
  end
end
