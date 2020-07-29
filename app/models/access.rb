class Access < ApplicationRecord
  ALLOWED_RESOURCES = %w[Organization FacilityGroup Facility].freeze

  belongs_to :user
  belongs_to :resource, polymorphic: true

  enum role: {
    viewer: "viewer",
    manager: "manager",
    super_admin: "super_admin"
  }

  validates :role, presence: true
  validates :user, uniqueness: {scope: [:resource_id, :resource_type], message: "can only have one access per resource."}
  validates :resource, presence: {unless: :super_admin?, message: "is required if not a super_admin."}
  validates :resource, absence: {if: :super_admin?, message: "must be nil if super_admin"}
  validates :resource_type, inclusion: {in: ALLOWED_RESOURCES, unless: :super_admin?}

  class << self
    def organizations(action)
      resources_for(Organization, action)
    end

    def facility_groups(action)
      resources_for(FacilityGroup, action)
        .or(FacilityGroup.where(organization: organizations(action)))
    end

    def facilities(action)
      resources_for(Facility, action)
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

    def resources_for(resource_model, action)
      return resource_model.all if super_admin.exists?
      resource_model.where(id: where(resource_type: resource_model.to_s, role: roles_for(action)).pluck(:resource_id))
    end
  end
end
