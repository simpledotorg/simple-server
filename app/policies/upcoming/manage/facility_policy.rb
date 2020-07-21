class Upcoming::Manage::FacilityPolicy < Upcoming::ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def allowed?
    return true if user.super_admin?
    user.accesses.admin.facilities.where(id: resolve_record(record, Facility)).exists?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if user.super_admin?
      scope.where(id: user.accesses.admin.facilities)
    end
  end
end
