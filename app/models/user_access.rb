class UserAccess < Struct.new(:user)
  include Memery
  class NotAuthorizedError < StandardError; end

  class AuthorizationNotPerformedError < StandardError; end

  LEVELS = {
    call_center: {
      id: :call_center,
      name: "Manage: Overdue List",
      grant_access: [],
      description: "Can view and update overdue lists"
    },

    viewer_reports_only: {
      id: :viewer_reports_only,
      name: "View: Aggregate Reports",
      grant_access: [],
      description: "Can view reports"
    },

    viewer_all: {
      id: :viewer_all,
      name: "View: Everything",
      grant_access: [],
      description: "Can view everything"
    },

    manager: {
      id: :manager,
      name: "Manager",
      grant_access: [:call_center, :viewer_reports_only, :viewer_all, :manager],
      description: "Can manage stuff"
    },

    power_user: {
      id: :power_user,
      name: "Power User",
      description: "Can manage everything"
    }
  }.freeze

  ANY_ACTION = :any
  ACTION_TO_LEVEL = {
    manage_overdue_list: [:manager, :viewer_all, :call_center],
    view_reports: [:manager, :viewer_all, :viewer_reports_only],
    view_pii: [:manager, :viewer_all],
    manage: [:manager]
  }.freeze

  memoize def accessible_organizations(action)
    resources_for(Organization, action)
  end

  memoize def accessible_facility_groups(action)
    resources_for(FacilityGroup, action)
      .union(FacilityGroup.where(organization: accessible_organizations(action)))
      .includes(:organization)
  end

  memoize def accessible_facilities(action)
    resources_for(Facility, action)
      .union(Facility.where(facility_group: accessible_facility_groups(action)))
      .includes(facility_group: :organization)
  end

  memoize def accessible_admins(action)
    return User.admins if bypass?
    return User.none if action_to_level(action).include?(:manage)

    User.admins.where(organization: user.organization)
  end

  memoize def accessible_users
    facilities = accessible_facilities(:manage)

    User.joins(:phone_number_authentications)
      .where.not(phone_number_authentications: {id: nil})
      .where(phone_number_authentications: {registration_facility_id: facilities})
  end

  def permitted_access_levels
    return LEVELS.keys if bypass?

    LEVELS[user.access_level.to_sym][:grant_access]
  end

  def grant_access(new_user, selected_facility_ids)
    return if selected_facility_ids.blank?
    raise NotAuthorizedError unless permitted_access_levels.include?(new_user.access_level.to_sym)

    resources = prepare_grantable_resources(selected_facility_ids)
    # if the user couldn't prepare resources for new_user means they shouldn't have had access to this operation at all
    raise NotAuthorizedError if resources.empty?

    # recreate accesses from scratch to handle deletes/edits/updates seamlessly
    User.transaction do
      new_user.accesses.delete_all
      new_user.accesses.create!(resources)
    end
  end

  private

  def resources_for(resource_model, action)
    return resource_model.all if bypass?
    return resource_model.none unless action_to_level(action).include?(user.access_level.to_sym)

    resource_ids =
      user
        .accesses
        .where(resource_type: resource_model.to_s)
        .map(&:resource_id)

    resource_model.where(id: resource_ids)
  end

  #
  # Compare the new user's selected facilities with the currently accessible facilities of the current user
  # and see if we can promote the new user's access if necessary
  def prepare_grantable_resources(selected_facility_ids)
    selected_facilities = Facility.where(id: selected_facility_ids).includes(facility_group: :organization)
    resources = []

    accessible_facilities_in_org = accessible_facilities(:manage).group_by(&:organization)
    selected_facilities.group_by(&:organization).each do |org, selected_facilities_in_org|
      if accessible_organizations(:manage).find_by_id(org).present? &&
          (accessible_facilities_in_org[org].to_set == selected_facilities_in_org.to_set)

        resources << {resource_type: Organization.name, resource_id: org.id}
        selected_facilities -= selected_facilities_in_org
      end
    end

    accessible_facilities_in_fg = accessible_facilities(:manage).group_by(&:facility_group)
    selected_facilities.group_by(&:facility_group).each do |fg, selected_facilities_in_fg|
      if accessible_facility_groups(:manage).find_by_id(fg).present? &&
          (accessible_facilities_in_fg[fg].to_set == selected_facilities_in_fg.to_set)
        
        resources << {resource_type: FacilityGroup.name, resource_id: fg.id}
        selected_facilities -= selected_facilities_in_fg
      end
    end

    selected_facilities.each do |f|
      if accessible_facilities(:manage).find_by_id(f).present?
        resources << {resource_type: Facility.name, resource_id: f.id}
      end
    end

    resources.flatten
  end

  def bypass?
    user.power_user?
  end

  def action_to_level(action)
    ACTION_TO_LEVEL.values.flatten.uniq if action == ANY_ACTION
    ACTION_TO_LEVEL.values[action]
  end
end
