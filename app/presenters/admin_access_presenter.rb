class AdminAccessPresenter < SimpleDelegator
  include Memery

  attr_reader :admin

  def initialize(admin)
    @admin = admin
    super
  end

  memoize def access_tree
    UserAccessTree.new(admin)
  end

  def permitted_access_levels_info
    UserAccess::LEVELS
      .slice(*admin.permitted_access_levels)
      .map { |_level, info| info.values_at(:name, :id) }
  end

  def visible_access_tree
    if admin.access_across_organizations?(:view)
      {
        data: access_tree.organizations,
        render_partial: "email_authentications/invitations/access_tree",
      }
    elsif admin.access_across_facility_groups?(:view)
      {
        data: access_tree.facility_groups,
        render_partial: "email_authentications/invitations/facility_group_access_tree",
      }
    else
      {
        data: access_tree.facilities,
        render_partial: "email_authentications/invitations/facility_access_tree",
      }
    end
  end
end
