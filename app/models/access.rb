# frozen_string_literal: true

class Access < ApplicationRecord
  ALLOWED_RESOURCES = %w[Organization FacilityGroup Facility].freeze

  belongs_to :user
  belongs_to :resource, polymorphic: true

  validates :user, uniqueness: {scope: [:resource_id, :resource_type], message: "can only have 1 access per resource."}
  validates :resource_type, inclusion: {in: ALLOWED_RESOURCES}
  validates :resource, presence: true
  validate :user_is_not_a_power_user, if: -> { user.present? }

  private

  def user_is_not_a_power_user
    if user.power_user?
      errors.add(:user, "cannot have accesses if they are a power user.")
    end
  end
end
