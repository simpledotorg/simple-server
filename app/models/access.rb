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
end
