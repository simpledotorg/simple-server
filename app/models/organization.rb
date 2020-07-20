class Organization < ApplicationRecord
  extend FriendlyId

  has_many :facility_groups, dependent: :destroy
  has_many :facilities, through: :facility_groups
  has_many :users
  has_many :protocols, through: :facility_groups

  validates :name, presence: true

  friendly_id :name, use: :slugged

  auto_strip_attributes :name, squish: true, upcase_first: true

  def districts
    facilities.select(:district).distinct.pluck(:district)
  end

  def organizations
    [self]
  end
end
