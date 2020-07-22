class Upcoming::Manage::FacilityGroupPolicy < Upcoming::ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def allowed?
    return true if user.super_admin?
    user.accesses.admin.where(resource: resolve_record(record, FacilityGroup)).exists?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if user.super_admin?
      scope.where(id: user.accesses.admin.facility_groups)
    end
  end
end
