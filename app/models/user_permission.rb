class UserPermission < ApplicationRecord
  belongs_to :master_user
  belongs_to :resource, polymorphic: true
end