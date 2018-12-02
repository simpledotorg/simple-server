class FacilityGroup < ApplicationRecord
  belongs_to :organization
  has_many :facilities, dependent: :nullify
  has_many :users, through: :facilities

  validates :name, presence: true
  validates :organization, presence: true
end
