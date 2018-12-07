class FacilityGroup < ApplicationRecord
  belongs_to :organization
  has_many :facilities, dependent: :nullify
  has_many :users, through: :facilities

  has_many :admin_access_controls
  has_many :admins, through: :admin_access_controls

  validates :name, presence: true
  validates :organization, presence: true
end
