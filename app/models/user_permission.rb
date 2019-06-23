class UserPermission < ApplicationRecord
  belongs_to :user
  belongs_to :resource, polymorphic: true, optional: true

  validates :permission_slug, presence: true
end