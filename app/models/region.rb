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
    root_kind = RegionKind.find_by!(name: "Root")
    org_kind = root_kind.children.first
    facility_group_kind = org_kind.children.first
    block_kind = facility_group_kind.children.first
    facility_kind = block_kind.children.first

    current_country_name = CountryConfig.current[:name]
    instance = Region.create! name: current_country_name, path: current_country_name, kind: root_kind
    Organization.all.each do |org|
      org_region = create_region_from(source: org, kind: org_kind, parent: instance)

      org.facility_groups.each do |facility_group|
        facility_group_region = create_region_from(source: facility_group, kind: facility_group_kind, parent: org_region)

        facility_group.facilities.group_by(&:zone).each do |block_name, facilities|
          block_region = create_region_from(name: block_name, kind: block_kind, parent: facility_group_region)
          facilities.each do |facility|
            create_region_from(source: facility, kind: facility_kind, parent: block_region)
          end
        end
      end
    end
  end
end
