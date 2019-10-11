class UserPermission < ApplicationRecord
  belongs_to :user
  belongs_to :resource, polymorphic: true, optional: true
end