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
    UserAccess::LEVELS.slice(*admin.permitted_access_levels)
  end

  memoize def access_tree
    UserAccessTree.new(admin)
  end

  delegate :visible?, to: :access_tree

  def visible_access_tree
    if admin.access_across_organizations?(:view)
      {
        data: access_tree.organizations,
        render_partial: "email_authentications/invitations/access_tree",
        root: :organization
      }
    elsif admin.access_across_facility_groups?(:view)
      {
        data: access_tree.facility_groups,
        render_partial: "email_authentications/invitations/facility_group_access_tree",
        root: :facility_group
      }
    else
      {
        data: access_tree.facilities,
        render_partial: "email_authentications/invitations/facility_access_tree",
        root: :facility
      }
    end
  end
end
