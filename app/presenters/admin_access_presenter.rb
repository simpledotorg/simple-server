require "ostruct"

class AdminAccessPresenter < SimpleDelegator
  include Memery

  DEPTH_LEVEL_TO_PARTIAL = {
    organization: "email_authentications/invitations/access_tree",
    facility_group: "email_authentications/invitations/facility_group_access_tree",
    facility: "email_authentications/invitations/facility_access_tree"
  }.freeze

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

  def access_tree_to_partial(access_tree)
    DEPTH_LEVEL_TO_PARTIAL.fetch(access_tree.fetch(:depth_level))
  end

  def access_tree
    if admin.access_across_organizations?(:view)
      {
        data: organization_tree,
        depth_level: :organization,
      }
    elsif admin.access_across_facility_groups?(:view)
      {
        data: facility_group_tree,
        depth_level: :facility_group,
      }
    else
      {
        data: facility_tree,
        depth_level: :facility,
      }
    end
  end

  def pre_selected?(model, record)
    case model
      when :facility
        admin.facility_tree.dig(record, :full_access)
      when :facility_group
        admin.facility_group_tree.dig(record, :full_access)
      when :organization
        admin.organization_tree.dig(record, :full_access)
      else
        raise ArgumentError, "Access to #{model} is unsupported."
    end
  end

  memoize def facility_tree
    visible_facilities.map do |facility|
      info = {
        full_access: true
      }

      [facility, info]
    end.to_h
  end

  memoize def facility_group_tree
    facility_tree
      .group_by { |facility, _| facility.facility_group }
      .map do |facility_group, facilities|

      info = {
        accessible_facility_count: facilities.length,
        full_access: visible_facility_groups.include?(facility_group),
        facilities: facilities,
      }

      [facility_group, info]
    end.to_h
  end

  memoize def organization_tree
    facility_group_tree
      .group_by { |facility_group, _| facility_group.organization }
      .map do |organization, facility_groups|

      info = {
        accessible_facility_count: facility_groups.sum { |_, info| info[:accessible_facility_count] },
        full_access: visible_organizations.include?(organization),
        facility_groups: facility_groups,
      }

      [organization, info]
    end.to_h
  end

  memoize def visible_facility_groups
    admin.accessible_facility_groups(:view)
  end

  memoize def visible_facilities
    admin.accessible_facilities(:view)
  end

  memoize def visible_organizations
    admin.accessible_organizations(:view)
  end
end
