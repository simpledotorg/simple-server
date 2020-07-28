class Access < ApplicationRecord
  ALLOWED_RESOURCE_TYPES = %w[Organization FacilityGroup Facility].freeze

  belongs_to :user
  belongs_to :resource, polymorphic: true, optional: true

  enum mode: {
    viewer: "viewer",
    manager: "manager",
    super_admin: "super_admin"
  }

  validates :mode, presence: true
  validates :resource_type, inclusion: {in: ALLOWED_RESOURCE_TYPES}, allow_nil: true
end
