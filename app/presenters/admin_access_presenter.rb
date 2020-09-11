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

  def permitted_access_levels
    UserAccess::LEVELS.slice(*admin.permitted_access_levels).values
  end

  def visible_access_tree
    if admin.access_across_organizations?(:any)
      {
        data: organization_tree,
        render_partial: "email_authentications/invitations/organization_access_tree",
        root: :organization
      }
    elsif admin.access_across_facility_groups?(:any)
      {
        data: facility_group_tree,
        render_partial: "email_authentications/invitations/facility_group_access_tree",
        root: :facility_group
      }
    else
      {
        data: visible_facilities,
        render_partial: "email_authentications/invitations/facility_access_tree",
        root: :facility
      }
    end
  end

  memoize def organization_tree
    facility_group_tree
      .group_by { |facility_group, _facilities| facility_group.organization }
      .transform_values(&:to_h)
      .sort_by { |organization, _| organization.name }
  end

  memoize def facility_group_tree
    visible_facilities
      .group_by(&:facility_group)
      .sort_by { |facility_group, _| facility_group.name }
  end

  memoize def visible_organizations
    admin.accessible_organizations(:any)
  end

  memoize def visible_facility_groups
    admin.accessible_facility_groups(:any)
  end

  memoize def visible_facilities
    admin.accessible_facilities(:any).order(:name)
  end

  alias_method :eql?, :==

  def ==(other)
    admin == other.admin
  end
end
