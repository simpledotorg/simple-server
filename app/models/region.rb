class Region < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  enum level: {
    organization: 10,
    state: 20,
    facility_group: 30,
    facility: 40
  }

  validates :name, presence: true
  validates :slug, presence: true

  belongs_to :parent_region, polymorphic: true, optional: true
  has_many :_child_regions, as: :parent_region, class_name: "Region"
  has_many :_facility_groups, inverse_of: :parent_region, foreign_key: :parent_region_id

  def top_level?
    parent_region.nil?
  end

  def children
    if state?
      _facility_groups
    else
      _child_regions
    end
  end
end
