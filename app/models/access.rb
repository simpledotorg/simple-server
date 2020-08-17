class Access < ApplicationRecord
  ALLOWED_RESOURCES = %w[Organization FacilityGroup Facility].freeze
  ACTION_TO_ROLE = {
    view: [:manager, :viewer],
    manage: [:manager]
  }

  belongs_to :user
  belongs_to :resource, polymorphic: true, optional: true

  enum role: {
    viewer: "viewer",
    manager: "manager",
    super_admin: "super_admin"
  }

  ROLE_DESCRIPTIONS = [
    {
      name: Access.roles.fetch_values(:viewer).first,
      description: "Can view stuff"
    },

    {
      name: Access.roles.fetch_values(:manager).first,
      description: "Can manage stuff"
    },

    {
      name: Access.roles.fetch_values(:super_admin).first,
      description: "Can manage everything"
    }
  ]

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

    def can?(action, model, record = nil)
      if record&.is_a? ActiveRecord::Relation
        raise ArgumentError, "record should not be an ActiveRecord::Relation."
      end

      case model
        when :facility
          can_access_record?(facilities(action), record)
        when :organization
          can_access_record?(organizations(action), record)
        when :facility_group
          can_access_record?(facility_groups(action), record)
        else
          raise ArgumentError, "Access to #{model} is unsupported."
      end
    end

    private

    def can_access_record?(resources, record)
      return resources.exists? if super_admin?
      return resources.find_by_id(record).present? if record

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
