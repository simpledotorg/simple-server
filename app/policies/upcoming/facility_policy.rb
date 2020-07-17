class Upcoming::FacilityPolicy < Upcoming::ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      organizations =
        Facility.where(id: user
                             .accesses
                             .where(resource_type: "Organization")
                             .map(&:resource)
                             .map(&:facilities))
      facility_groups =
        Facility.where(id: user
                             .accesses
                             .where(resource_type: "FacilityGroup")
                             .map(&:resource)
                             .map(&:facilities))
      facilities =
        Facility.where(id: user
                             .accesses
                             .where(resource_type: "Facility")
                             .map(&:resource))

      organizations.union(facility_groups).union(facilities)
    end
  end
end
