class Upcoming::Read::OrganizationPolicy < Upcoming::ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def allowed?
    return true if user.super_admin?
    user.accesses.where(resource: resolve_record(record, Organization)).exists?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if user.super_admin?

      Organization
        .where(id: user.accesses.organizations)
        .or(Organization
              .where(facility_groups: FacilityGroup
                                        .where(id: user.accesses.facility_groups)
                                        .or(FacilityGroup.where(facility: user.accesses.facilities))))
    end
  end
end
