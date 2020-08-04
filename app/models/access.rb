class Access < ApplicationRecord
  ALLOWED_RESOURCES = %w[Organization FacilityGroup Facility].freeze

  belongs_to :user
  belongs_to :resource, polymorphic: true

  enum role: {
    viewer: "viewer",
    manager: "manager",
    super_admin: "super_admin"
  }

  ACTION_TO_ROLE = {
    view: [:manager, :viewer],
    manage: [:manager]
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

    def can?(action, model, record = nil)
      case model
      when :facility
        accessible_resources(facilities(action), record).exists?
      when :organization
        accessible_resources(organizations(action), record).exists?
      when :facility_group
        accessible_resources(facility_groups(action), record).exists?
      else
        raise ArgumentError, "Invalid model: #{model}"
      end
    end

    def accessible_resources(resources, record)
      return resources.where(id: record) if record
      resources
    end

    private

    def resources_for(resource_model, action)
      return resource_model.all if super_admin.exists?
      resource_model.where(id: where(resource_type: resource_model.to_s, role: ACTION_TO_ROLE[action])
                                 .pluck(:resource_id))
    end
  end
end
