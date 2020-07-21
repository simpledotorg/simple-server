class Upcoming::Manage::FacilityGroupPolicy < Upcoming::ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def allowed?
    return true if user.super_admin?

    record = resolve_record(record, FacilityGroup)
    admin_accesses = user.accesses.admin
    organizations = Organization.includes(:facility_groups).where(facility_groups: record)
    admin_accesses
      .where(resource: organizations)
      .or(admin_accesses.where(resource: record))
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
      FacilityGroup.where(id: user.accesses.admin.map(&:resource).map(&:facility_groups))
    end
  end
end
