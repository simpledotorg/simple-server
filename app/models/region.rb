class Region < ApplicationRecord
  ltree :path
  extend FriendlyId
  friendly_id :name, use: :slugged

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

  def self.backfill
    root_kind = RegionKind.create! name: "Root", path: "Root"
    org_kind = RegionKind.create! name: "Organization", path: "Root.Organization"
    facility_group_kind = RegionKind.create! name: "FacilityGroup", path: "Root.Organization.FacilityGroup"
    block_kind = RegionKind.create! name: "Block", path: "Root.Organization.FacilityGroup.Block"
    facility_kind = RegionKind.create! name: "Facility", path: "Root.Organization.FacilityGroup.Block.Facility"

    root_region = Region.create! name: "TestInstance", kind: root_kind, path: "TestInstance"

    Organization.all.each do |org|
      org_region = create_region_from(source: org, kind: org_kind, parent: root_region)

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