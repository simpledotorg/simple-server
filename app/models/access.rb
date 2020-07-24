class Access < ApplicationRecord
  ALLOWED_RESOURCE_TYPES = %w[Organization FacilityGroup Facility].freeze

  belongs_to :user
  belongs_to :resource, polymorphic: true, optional: true

  enum role: {
    super_admin: "super_admin",
    admin: "admin",
    analyst: "analyst"
  }

  validates :role, presence: true
  validates :resource_type, inclusion: {in: ALLOWED_RESOURCE_TYPES}, allow_nil: true

  class << self
    def can_manage_facilities?(record)
      return true if super_admin.exists?

      manageable_facilities = facilities(role: :admin)

      record =
        if record.instance_of?(Facility)
          record
        else
          manageable_facilities
        end

      manageable_facilities
        .where(id: record)
        .exists?
    end

    def can_read_aggregates?
      super_admin.exists? || exists?
    end

    def can_view_identifiable_info?
      super_admin.exists? || admin.exists?
    end

    def organizations(role)
      resources_for(Organization, role)
    end

    def facility_groups(role)
      facility_groups = resources_for(FacilityGroup, role)
      facility_groups.or(facility_groups.where(organization: organizations(role)))
    end

    def facilities(role)
      facilities = resources_for(Facility, role)
      facilities.or(facilities.where(facility_group: facility_groups(role)))
    end

    private

    def resources_for(scope, role)
      scope.where(id: where(resource_type: scope.to_s, role: role).pluck(:resource_id))
    end
  end
end
