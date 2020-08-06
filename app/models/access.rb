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
  validate :user_has_only_one_role, if: -> { user.present? }

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

    def can?(action, model, records = nil)
      case model
        when :facility
          can_access_records?(facilities(action), records)
        when :organization
          can_access_records?(organizations(action), records)
        when :facility_group
          can_access_records?(facility_groups(action), records)
        else
          raise ArgumentError, "Access to #{model} is unsupported."
      end
    end

    private

    def can_access_records?(resources, records)
      return resources.exists? if super_admin?
      return resources.where(id: records).exists? if records

      resources.exists?
    end

    def resources_for(resource_model, action)
      return resource_model.all if super_admin?

      resource_ids = where(resource_type: resource_model.to_s, role: ACTION_TO_ROLE[action]).pluck(:resource_id)
      resource_model.where(id: resource_ids)
    end

    def super_admin?
      super_admin.exists?
    end
  end

  private

  def user_has_only_one_role
    existing_role = user.accesses.pluck(:role).uniq.first

    if existing_role.present? && existing_role != role
      errors.add(:user, "can only have one role.")
    end
  end
end
