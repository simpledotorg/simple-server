class AdminAccessControl < ApplicationRecord
  belongs_to :admin
  belongs_to :facility_group

  validates :admin, presence: true
  validates :facility_group, presence: true
end
