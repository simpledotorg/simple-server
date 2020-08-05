class AccessibleResource < ApplicationRecord
  ALLOWED_RESOURCES = %w[Organization FacilityGroup Facility].freeze

  belongs_to :user
  belongs_to :resource, polymorphic: true

  validates :user, uniqueness: {scope: [:resource_id, :resource_type], message: "user resource already exists."}
  validates :resource_type, inclusion: {in: ALLOWED_RESOURCES}
end
