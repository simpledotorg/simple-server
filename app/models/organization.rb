class Organization < ApplicationRecord
  extend FriendlyId
  extend RegionSource

  has_many :facility_groups, dependent: :destroy
  has_many :facilities, through: :facility_groups
  has_many :appointments, through: :facilities
  has_many :users
  has_many :protocols, through: :facility_groups

  validates :name, presence: true

  friendly_id :name, use: :slugged

  auto_strip_attributes :name, squish: true, upcase_first: true

  # ----------------
  # Region callbacks
  after_save :create_region, on: :create
  after_save :update_region, on: :update

  def create_region
    parent_region_type = RegionType.find_by_name("Root")
    new_parent = Region.find_by(type: parent_region_type)

    region.type = RegionType.find_by_name("Organization")
    region.source = self
    region.parent = new_parent
    region.name = name
    region.save!
  end

  def update_region
    region.name = name
    region.save!
  end
  # ----------------

  def districts
    facilities.select(:district).distinct.pluck(:district)
  end

  def discardable?
    facility_groups.none? && users.none? && appointments.none?
  end
end
