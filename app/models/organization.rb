class Organization < ApplicationRecord
  extend FriendlyId
  extend RegionSource

  has_many :facility_groups, dependent: :destroy
  has_many :facilities, through: :facility_groups
  has_many :appointments, through: :facilities
  has_many :users
  has_many :protocols, through: :facility_groups
  has_many :registered_patients, through: :facility_groups

  validates :name, presence: true

  friendly_id :name, use: :slugged

  auto_strip_attributes :name, squish: true, upcase_first: true

  # ----------------
  # Region callbacks
  after_create :create_region, if: -> { Flipper.enabled?(:region_level_sync) }
  before_update :update_region, if: -> { Flipper.enabled?(:region_level_sync) }

  def create_region
    return if region&.persisted?

    parent = Region.find_by!(region_type: Region.region_types[:root])
    region = build_region(name: name, description: description, reparent_to: parent)
    region.region_type = Region.region_types[:organization]
    region.save!
  end

  def update_region
    return unless name_changed? || description_changed?

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

  def syncable_patients
    registered_patients.with_discarded
  end
end
