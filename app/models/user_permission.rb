class UserPermission < ApplicationRecord
  belongs_to :user
  belongs_to :resource, polymorphic: true, optional: true

  validates :permission_slug, presence: true,
                              inclusion: {in: Permissions::VALID_PERMISSION_SLUGS, message: "is not a known permission"}
end
