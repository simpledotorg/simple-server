class AdminAccessControl < ApplicationRecord
  belongs_to :admin
  belongs_to :access_controllable, polymorphic: true

  validates :admin, presence: true
end