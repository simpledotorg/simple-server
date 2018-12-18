class Organization < ApplicationRecord
  has_many :facility_groups, dependent: :destroy
  has_many :facilities, through: :facility_groups
  has_many :users, through: :facilities

  validates :name, presence: true
end
