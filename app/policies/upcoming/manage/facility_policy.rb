class Upcoming::Manage::FacilityPolicy < Upcoming::ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def allowed?
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
      Facility.where(id: user.accesses.admin.map(&:resource).map(&:facilities))
    end
  end
end
