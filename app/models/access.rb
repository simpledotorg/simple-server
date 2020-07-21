class Access < ApplicationRecord
  ALLOWED_RESOURCE_TYPES = %w[Organization FacilityGroup Facility].freeze

  belongs_to :user
  belongs_to :resource, polymorphic: true, optional: true

  enum role: {
    super_admin: "super_admin",
    admin: "admin",
    analyst: "analyst"
  }

  validates :resource_type, inclusion: {in: ALLOWED_RESOURCE_TYPES}, allow_nil: true

  class << self
    def organizations
      resources_for(Organization)
        .or(Organization.where(facilities: resources_for(Facility)))
        .or(Organization.where(facility_groups: resources_for(FacilityGroup)))
    end

    def facilities
      resources_for(Facility)
        .or(Facility.where(facility_group: FacilityGroup.where(organization: resources_for(Organization))))
        .or(Facility.where(facility_group: resources_for(FacilityGroup)))
    end

    def facility_groups
      resources_for(FacilityGroup)
        .or(FacilityGroup.where(organization: resources_for(Organization)))
        .or(FacilityGroup.where(facilities: resources_for(Facility)))
    end

    private

    def resources_for(type)
      type.where(id: where(resource_type: type.to_s).pluck(:resource_id))
    end
  end
end
