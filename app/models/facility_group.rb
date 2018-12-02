class FacilityGroup < ApplicationRecord
  belongs_to :organization
  has_many :facilities
  has_many :users, through: :facilities

  validates :name, presence: true
  validates :organization, presence: true
end
