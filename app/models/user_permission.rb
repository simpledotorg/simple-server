class UserPermission < ApplicationRecord
  belongs_to :user
  belongs_to :resource, polymorphic: true, optional: true

  validates_presence_of :permission_slug
end