class FacilityGroup < ApplicationRecord
  belongs_to :organization
  has_many :facilities

  validates :name, presence: true
  validates :organization, presence: true
end
