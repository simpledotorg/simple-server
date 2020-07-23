class Region < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  enum level: {
    root: 0,
    organization: 10,
    state: 20,
    facility_group: 30,
    facility: 40
  }

  belongs_to :parent_region, polymorphic: true, optional: true
  has_many :_child_regions, as: :parent_region, class_name: "Region"
  has_many :_facility_groups, inverse_of: :parent_region, foreign_key: :parent_region_id

  validates :level, presence: true, uniqueness: { conditions: -> { where(level: 0) }, message: "can only have one root Region" }
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :parent_region, presence: true, unless: :root?

  def self.root
    @root ||= Region.readonly.find_or_create_by!(name: "root", level: :root)
  end

  def root?
    level == "root"
  end

  def children
    if state?
      _facility_groups
    else
      _child_regions
    end
  end
end
