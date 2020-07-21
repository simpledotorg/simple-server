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
      where(resource_type: "Organization")
    end

    def facilities
      where(resource_type: "Facility")
    end

    def facility_groups
      where(resource_type: "FacilityGroup")
    end
  end
end
