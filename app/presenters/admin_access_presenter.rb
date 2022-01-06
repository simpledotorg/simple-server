# frozen_string_literal: true

require "ostruct"

class AdminAccessPresenter < SimpleDelegator
  include Memery

  attr_reader :admin_access_level
  attr_reader :admin

  def initialize(admin)
    super
    @admin = admin
    @admin_access_level = admin.access_level
  end

  def display_access_level
    access_level =
      if admin_access_level
        UserAccess::LEVELS.fetch(admin_access_level.to_sym)
      else
        {name: "(Not Set)", description: "N/A"}
      end

    OpenStruct.new(access_level)
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
      .sort_by { |organization, _| organization.name }
      .to_h
      .transform_values(&:to_h)
  end

  memoize def facility_group_tree
    visible_facilities
      .where.not(facility_group: nil)
      .group_by(&:facility_group)
      .sort_by { |facility_group, _| facility_group.name }
      .to_h
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
