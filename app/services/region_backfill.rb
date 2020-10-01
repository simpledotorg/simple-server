class RegionBackfill
  def self.call
    new.call
  end

  def initialize
  end

  def call
    root_kind = RegionKind.find_by!(name: "Root")
    org_kind = root_kind.children.first
    facility_group_kind = org_kind.children.first
    block_kind = facility_group_kind.children.first
    facility_kind = block_kind.children.first

    current_country_name = CountryConfig.current[:name]
    instance = Region.create! name: current_country_name, path: current_country_name, kind: root_kind
    Organization.all.each do |org|
      org_region = Region.create_region_from(source: org, kind: org_kind, parent: instance)

      org.facility_groups.each do |facility_group|
        facility_group_region = Region.create_region_from(source: facility_group, kind: facility_group_kind, parent: org_region)

        facility_group.facilities.group_by(&:zone).each do |block_name, facilities|
          block_region = Region.create_region_from(name: block_name, kind: block_kind, parent: facility_group_region)
          facilities.each do |facility|
            Region.create_region_from(source: facility, kind: facility_kind, parent: block_region)
          end
        end
      end
    end
  end
end