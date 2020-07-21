class Upcoming::Read::FacilityGroupPolicy < Upcoming::ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def allowed?
    return true if user.super_admin?

    record = resolve_record(record, FacilityGroup)
    accesses = user.accesses
    organizations = Organization.includes(:facility_groups).where(facility_groups: record)
    accesses
      .where(resource: organizations)
      .or(accesses.where(resource: record))
      .exists?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if user.super_admin?
      scope.where(id: user.accesses.facility_groups)
    end
  end
end
