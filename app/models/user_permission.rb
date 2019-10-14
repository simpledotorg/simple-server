class UserPermission < ApplicationRecord
  belongs_to :user
  belongs_to :resource, polymorphic: true, optional: true

  validates :permission_slug, presence: true
  validates :resource, presence: true, if: -> {
    Permissions::ALL_PERMISSIONS[permission_slug.to_sym][:type] != :global
  }

  validates_uniqueness_of :permission_slug, scope: [:user, :resource]
end