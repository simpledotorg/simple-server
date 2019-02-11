class AppointmentPolicy < ApplicationPolicy
  def index?
    user.owner? || user.counsellor?
  end

  def edit?
    index?
  end

  def update?
    edit?
  end

  def cancel?
    edit?
  end

  def cancel_with_reason?
    cancel?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(patient: @user.patients, facility: @user.facilities)
    end
  end
end
