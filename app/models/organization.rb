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
  #
  # - These callbacks are medium-term temporary.
  # - This class and the Region callbacks should ideally be totally superseded by the Region class.
  # - Keep these callbacks simple (avoid too much branching and optimization), idempotent and loud when things break.
  #
  # - kit
  after_create :create_region, if: -> { Flipper.enabled?(:regions_prep) }
  after_update :update_region, if: -> { Flipper.enabled?(:regions_prep) }

  def create_region
    return if region&.persisted?

    create_region!(
      name: name,
      description: description,
      reparent_to: root_region,
      region_type: Region.region_types[:organization]
    )
  end

  def update_region
    region.name = name
    region.description = description
    region.save!
  end

  def root_region
    Region.find_by!(region_type: Region.region_types[:root])
  end
  # ----------------

  def districts
    facilities.select(:district).distinct.pluck(:district)
  end

  def discardable?
    facility_groups.none? && users.none? && appointments.none?
  end
end
