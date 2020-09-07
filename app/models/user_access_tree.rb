#
# Even with Rails caching most of the access-related queries,
# the sheer volume of the number of queries can really slow down page rendering
#
# This class tries to provide an easy and fast way (mostly constant time) to lookup the visible access tree of a user
class UserAccessTree < Struct.new(:user)
  include Memery

  memoize def facilities
    visible_facilities
      .map { |facility|
        info = {
          visible: true
        }

        [facility, info]
      }
      .sort_by { |f, _| f[:name] }
      .to_h
  end

  memoize def facility_groups
    facilities
      .group_by { |facility, _| facility.facility_group }
      .map { |facility_group, facilities_in_fg|
        info = {
          accessible_facility_count: facilities_in_fg.length,
          visible: visible_facility_groups.include?(facility_group),
          facilities: facilities_in_fg
        }

        [facility_group, info]
      }
      .sort_by { |fg, _| fg[:name] }
      .to_h
  end

  memoize def organizations
    facility_groups
      .group_by { |facility_group, _| facility_group.organization }
      .map { |organization, facility_groups_in_org|
        info = {
          accessible_facility_count: facility_groups_in_org.sum { |_, info| info[:accessible_facility_count] },
          visible: visible_organizations.include?(organization),
          facility_groups: facility_groups_in_org
        }

        [organization, info]
      }
      .sort_by { |o, _| o[:name] }
      .to_h
  end

  def visible?(model, record)
    case model
      when :facility
        facilities.dig(record, :visible)
      when :facility_group
        facility_groups.dig(record, :visible)
      when :organization
        organizations.dig(record, :visible)
      else
        raise ArgumentError, "#{model} is unsupported."
    end
  end

  private

  memoize def visible_facility_groups
    user.accessible_facility_groups(:any)
  end

  memoize def visible_facilities
    user.accessible_facilities(:any)
  end

  memoize def visible_organizations
    user.accessible_organizations(:any)
  end
end
