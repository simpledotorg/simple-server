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
  after_create :create_region, if: -> { Region.root.present? }
  after_update :update_region, if: -> { Region.root.present? }

  def create_region
    parent = Region.find_by(region_type: Region.region_types[:root])
    region = Region.new
    region.region_type = Region.region_types[:organization]
    region.source = self
    region.parent = parent
    region.name = name
    region.description = description
    region.save!
  end

  def update_region
    region.name = name
    region.description = description
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
