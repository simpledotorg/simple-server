class Organization < ApplicationRecord
  extend FriendlyId

  has_many :facility_groups, dependent: :destroy
  has_many :facilities, through: :facility_groups
  has_many :users, through: :facilities
  has_many :protocols, through: :facility_groups

  has_many :admin_access_controls, as: :access_controllable
  has_many :admins, through: :admin_access_controls

  validates :name, presence: true

  friendly_id :name, use: :slugged

  def get_districts
    facilities.select(:district).distinct.pluck(:district)
  end
end
