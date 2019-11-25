module HasAdminAccessControls
  extend ActiveSupport::Concern

  included do
    has_many :admin_access_controls, inverse_of: :admin

    def has_role?(*roles)
      roles.map(&:to_sym).include?(self.role.to_sym)
    end

    def facility_groups
      return admin_access_controls.map(&:access_controllable) if (supervisor? || analyst? || counsellor?)
      return organizations.flat_map(&:facility_groups) if organization_owner?
      return FacilityGroup.all if owner?
      []
    end

    def organizations
      return facility_groups.map(&:organization).uniq if (supervisor? || analyst? || counsellor?)
      return admin_access_controls.map(&:access_controllable) if organization_owner?
      return Organization.all if owner?
      []
    end

    def protocols
      return Protocol.all if owner?
      facility_groups.map(&:protocol).uniq
    end

    def facilities
      return Facility.all if owner?
      facility_groups.flat_map(&:facilities)
    end

    def users
      return User.all if owner?
      facility_groups.flat_map(&:users)
    end

    def access_controllable_ids
      admin_access_controls.map(&:access_controllable_id)
    end
  end
end