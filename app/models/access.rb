class Access < ApplicationRecord
  ALLOWED_SCOPES = %w[Organization FacilityGroup Facility].freeze

  belongs_to :user
  belongs_to :scope, polymorphic: true, optional: true

  enum mode: {
    viewer: "viewer",
    manager: "manager",
    super_admin: "super_admin"
  }

  validates :mode, presence: true
  validates :scope_type, inclusion: {in: ALLOWED_SCOPES}, allow_nil: true

  class << self
    def organizations(action)
      resources_for(Organization, roles_for(action))
    end

    def facility_groups(action)
      resources_for(FacilityGroup, roles_for(action))
        .or(FacilityGroup.where(organization: organizations(action)))
    end

    def facilities(action)
      resources_for(Facility, roles_for(action))
        .or(Facility.where(facility_group: facility_groups(action)))
    end

    private

    def roles_for(action)
      case action
        when :view
          [:manager, :viewer]
        when :manage
          [:manager]
        else
          raise ArgumentError, "Invalid action: #{action}"
      end
    end

    def resources_for(scope, role)
      return scope.all if super_admin?
      scope.where(id: where(resource_type: scope.to_s, role: role).pluck(:resource_id))
    end
  end
end
