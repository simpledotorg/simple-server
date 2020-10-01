class Region < ApplicationRecord
  ltree :path
  extend FriendlyId
  friendly_id :name, use: :slugged

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :path, presence: true

  belongs_to :kind, class_name: "RegionKind", foreign_key: "region_kind_id"
  belongs_to :source, polymorphic: true, optional: true

  before_discard do
    self.path = nil
  end

  def self.create_region_from(parent:, kind:, name: nil, source: nil)
    raise ArgumentError, "Provide either a name or a source" if (name && source) || (name.blank? && source.blank?)
    region_name = name || source.name
    region = Region.new name: region_name, kind: kind
    region.send :set_slug
    region.source = source if source
    region.path = "#{parent.path}.#{region.slug.tr("-", "_")}"
    region.save!
    region
  end

  def self.backfill!
    RegionBackfill.backfill!
  end
end
