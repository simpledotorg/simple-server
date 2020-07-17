class Access < ApplicationRecord
  ALLOWED_TYPES = %w[Organization FacilityGroup Facility].freeze

  belongs_to :user
  belongs_to :resourceable, polymorphic: true, optional: true
  belongs_to :role

  enum role: {
    super_admin: "super_admin",
    admin: "admin",
    analyst: "analyst"
  }

  validates :resourceable_type, presence: true, inclusion: {in: ALLOWED_TYPES}
end
