require "ostruct"

class AdminAccessPresenter < SimpleDelegator
  include Memery

  attr_reader :admin

  def initialize(admin)
    @admin = admin
    super
  end

  def display_access_level
    OpenStruct.new(UserAccess::LEVELS.fetch(admin.access_level.to_sym))
  end

  def permitted_access_levels_info
    UserAccess::LEVELS
      .slice(*admin.permitted_access_levels)
      .map { |_level, info| info.values_at(:name, :id) }
  end

  def to_tree(depth)
    if access_across_organizations?
      organizations
    elsif access_across_facility_groups?
      facility_groups
    else
      facilities
    end
  end

  def access_across_organizations?
    admin.accessible_facilities(:view).group_by(&:organization).keys > 1
  end

  def access_across_facility_groups?
    admin.accessible_facilities(:view).group_by(&:facility_groups).keys > 1
  end

  memoize def facility_tree(user_being_edited: nil)
    accessible_facilities.map do |facility|
      info = {
        full_access: admin.can?(:view, :facility, facility),
        selected: selected?(user_being_edited, :facility_tree, facility)
      }

      [facility, OpenStruct.new(info)]
    end.to_h
  end

  memoize def facility_group_tree(user_being_edited: nil)
    accessible_facilities.flat_map(&:facility_group).map do |facility_group|
      facility_tree = facility_tree(user_being_edited: user_being_edited).select { |facility, _| facility.facility_group == facility_group }

      info = {
        accessible_facility_count: facility_tree.keys.size,
        total_facility_count: facility_group.facilities.length,
        facilities: facility_tree,
        full_access: admin.can?(:view, :facility_group, facility_group),
        selected: selected?(user_being_edited, :facility_group_tree, facility_group)
      }

      [facility_group, OpenStruct.new(info)]
    end.to_h
  end

  memoize def organization_tree(user_being_edited: nil)
    accessible_facilities.flat_map(&:organization).map do |organization|
      facility_group_tree = facility_group_tree(user_being_edited: user_being_edited).select { |fg, _| fg.organization == organization }

      info = {
        accessible_facility_group_count: facility_group_tree.keys.size,
        total_facility_group_count: organization.facility_groups.length,
        facility_groups: facility_group_tree,
        full_access: admin.can?(:view, :organization, organization),
        selected: selected?(user_being_edited, :organization_tree, organization)
      }

      [organization, OpenStruct.new(info)]
    end.to_h
  end

  private

  attr_reader :user_being_edited

  def selected?(user_being_edited, resource_tree, record)
    user_being_edited &&
      user_being_edited.public_send(resource_tree).key?(record) &&
      user_being_edited.public_send(resource_tree).dig(record, :full_access)
  end

  def accessible_facilities
    @accessible_facilities ||= admin.accessible_facilities(:view).includes(facility_group: :organization)
  end
end
