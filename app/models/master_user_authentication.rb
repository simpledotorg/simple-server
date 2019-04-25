class MasterUserAuthentication < ApplicationRecord
  belongs_to :master_user
  belongs_to :authenticatable, polymorphic: true

  validates_uniqueness_of :authenticatable_id, scope: [:master_user_id, :authenticatable_type]
end