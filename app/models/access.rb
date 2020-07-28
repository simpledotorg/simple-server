class Access < ApplicationRecord
  ALLOWED_RESOURCES = %w[Organization FacilityGroup Facility].freeze

  belongs_to :user
  belongs_to :resource, polymorphic: true

  enum mode: {
    viewer: "viewer",
    manager: "manager",
    super_admin: "super_admin"
  }

  validates :mode, presence: true
  validates :user, uniqueness: {scope: [:resource_id, :resource_type], message: "can only have one access per resource."}
  validates :resource, presence: {unless: :super_admin?, message: "is required if not a super_admin."}
  validates :resource, inclusion: {in: [nil], if: :super_admin?, message: "must be nil if super_admin"}
  validates :resource_type, inclusion: {in: ALLOWED_RESOURCES, unless: :super_admin?}
end
