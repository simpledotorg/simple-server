class Access < ApplicationRecord
  ALLOWED_RESOURCES = %w[Organization FacilityGroup Facility].freeze
  ACTION_TO_USER_ROLE = {
    view: User.access_levels.fetch_values(:manager, :viewer),
    manage: User.access_levels.fetch_values(:manager)
  }

  belongs_to :user
  belongs_to :resource, polymorphic: true

  validates :user, uniqueness: {scope: [:resource_id, :resource_type], message: "can only have 1 access per resource."}
  validates :resource_type, inclusion: {in: ALLOWED_RESOURCES}
  validates :resource, presence: true
  validate :user_is_not_a_power_user, if: -> { user.present? }


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
      return resources.find_by_id(record).present? if record
      resources.exists?
    end

    def resources_for(resource_model, action)
      resource_ids =
        where(resource_type: resource_model.to_s)
          .select { |access| access.user.access_level.in?(ACTION_TO_USER_ROLE[action]) }
          .map(&:resource_id)

      resource_model.where(id: resource_ids)
    end
  end

  private

  def user_is_not_a_power_user
    if user.power_user?
      errors.add(:user, "cannot have accesses if they are a power user.")
    end
  end
end
