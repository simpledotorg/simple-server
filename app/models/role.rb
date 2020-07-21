class Role < ApplicationRecord
  enum name: {
    super_admin: "super_admin",
    admin: "admin",
    analyst: "analyst"
  }
  belongs_to :user
  belongs_to :resource, polymorphic: true
  validates :name, presence: true

  scope :super_admin_or_admin, -> { where(name: [:super_admin, :admin]) }
end
