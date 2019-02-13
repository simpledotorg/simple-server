class AppointmentPolicy < ApplicationPolicy
  def index?
    user.owner? || user.counsellor?
  end

  def update?
    index?
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
