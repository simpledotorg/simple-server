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

  def access_tree(user_being_edited: nil)
    if access_across_organizations?
      {
        data: organization_tree(user_being_edited: nil),
        depth_level: :organization,
      }
    elsif access_across_facility_groups?
      {
        data: facility_group_tree(user_being_edited: nil),
        depth_level: :facility_group,
      }
    else
      {
        data: facility_tree(user_being_edited: nil),
        depth_level: :facility,
      }
    end
  end

  DEPTH_LEVEL_TO_PARTIAL = {
    organization: "email_authentications/invitations/access_tree",
    facility_group: "email_authentications/invitations/facility_group_access_tree",
    facility: "email_authentications/invitations/facility_access_tree"
  }.freeze

  def access_tree_to_partial(access_tree)
    DEPTH_LEVEL_TO_PARTIAL.fetch(access_tree.fetch(:depth_level))
  end

  def access_across_organizations?
    accessible_facilities.group_by(&:organization).keys.length > 1
  end

  def access_across_facility_groups?
    accessible_facilities.group_by(&:facility_group).keys.length > 1
  end

  memoize def facility_tree(user_being_edited: nil)
    accessible_facilities.map do |facility|
      info = {
        facility_group: facility.facility_group,
        full_access: true,
        selected: selected?(user_being_edited, :facility_tree, facility)
      }

      [facility, OpenStruct.new(info)]
    end.to_h
  end

  memoize def facility_group_tree(user_being_edited: nil)
    facility_tree(user_being_edited: user_being_edited)
      .group_by { |_facility, info| info.facility_group }
      .map do |facility_group, facilities|

      info = {
        accessible_facility_count: facilities.length,
        facilities: facilities,
        organization: facility_group.organization,
        full_access: accessible_facility_groups.include?(facility_group),
        selected: selected?(user_being_edited, :facility_group_tree, facility_group)
      }

      [facility_group, OpenStruct.new(info)]
    end.to_h
  end

  memoize def organization_tree(user_being_edited: nil)
    facility_group_tree(user_being_edited: user_being_edited)
      .group_by { |_facility_group, info| info.organization }
      .map do |organization, facility_groups|

      info = {
        accessible_facility_count: facility_groups.sum { |_fg, info| info.accessible_facility_count },
        facility_groups: facility_groups,
        full_access: accessible_organizations.include?(organization),
        selected: selected?(user_being_edited, :organization_tree, organization)
      }

      [organization, OpenStruct.new(info)]
    end.to_h
  end

  private

  attr_reader :user_being_edited

  def selected?(user_being_edited, resource_tree, record)
    return true if user_being_edited == admin

    user_being_edited &&
      user_being_edited.public_send(resource_tree).dig(record, :full_access)
  end

  memoize def accessible_facility_groups
    admin.accessible_facility_groups(:view)
  end

  memoize def accessible_facilities
    admin.accessible_facilities(:view).includes(facility_group: :organization)
  end

  memoize def accessible_organizations
    admin.accessible_organizations(:view)
  end
end
