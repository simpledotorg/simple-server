class Upcoming::Manage::FacilityPolicy < Upcoming::ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def allowed?
    return true if user.super_admin?

    record = resolve_record(record, Facility)
    admin_accesses = user.accesses.admin
    facility_groups = FacilityGroup.includes(:facilities).where(facilities: record)
    organizations = Organization.includes(:facility_groups).where(facility_groups: facility_groups)
    admin_accesses
      .where(resource: organizations)
      .or(admin_accesses.where(resource: facility_groups))
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

      Facility
        .where(id: user.accesses.admin.facilities)
        .or(Facility
              .where(facility_group: FacilityGroup
                                       .where(organization: user.accesses.admin.organizations)
                                       .or(FacilityGroup.where(id: user.accesses.admin.facility_groups))))
    end
  end
end
