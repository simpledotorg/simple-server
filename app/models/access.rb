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

      manageable_facilities = facilities(:manage)

      if record.instance_of?(Facility)
        manageable_facilities.where(id: record).exists?
      else
        manageable_facilities.exists?
      end
    end

    def can_manage_facility_groups?(record)
      return true if super_admin.exists?

      manageable_facility_groups = facility_groups(:manage)

      if record.instance_of?(FacilityGroup)
        manageable_facility_groups.where(id: record).exists?
      else
        manageable_facility_groups.exists?
      end
    end

    def can_manage_organizations?(record)
      return true if super_admin.exists?

      manageable_organizations = organizations(:manage)

      if record.instance_of?(Organization)
        manageable_organizations.where(id: record).exists?
      else
        manageable_organizations.exists?
      end
    end

    def super_admin?
      super_admin.exists?
    end

    def can_read_aggregates?
      super_admin.exists? || exists?
    end

    def can_view_identifiable_info?
      super_admin.exists? || admin.exists?
    end

    def organizations(action)
      return Organization.all if super_admin?

      resources_for(Organization, roles_for(action))
    end

    def facility_groups(action)
      return FacilityGroup.all if super_admin?

      resources_for(FacilityGroup, roles_for(action))
        .or(FacilityGroup.where(organization: organizations(action)))
    end

    def facilities(action)
      return Facility.all if super_admin?

      resources_for(Facility, roles_for(action))
        .or(Facility.where(facility_group: facility_groups(action)))
    end

    private

    def roles_for(action)
      case action
        when :view
          [:admin, :analyst]
        when :manage
          [:admin]
        else
          raise ArgumentError, "Invalid action: #{action}"
      end
    end

    def resources_for(scope, role)
      scope.where(id: where(resource_type: scope.to_s, role: role).pluck(:resource_id))
    end
  end
end
