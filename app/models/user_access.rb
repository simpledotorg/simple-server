class UserAccess < Struct.new(:user)
  class NotAuthorizedError < StandardError; end

  LEVELS = {
    viewer: {
      id: :viewer,
      name: "View: Everything",
      grant_access: [],
      description: "Can view stuff"
    },

    manager: {
      id: :manager,
      name: "Manager",
      grant_access: [:viewer, :manager],
      description: "Can manage stuff"
    },

    power_user: {
      id: :power_user,
      name: "Power User",
      description: "Can manage everything"
    }
  }.freeze

  ACTION_TO_LEVEL = {
    view: [:manager, :viewer],
    manage: [:manager]
  }.freeze

  def accessible_organizations(action)
    resources_for(Organization, action)
  end

  def accessible_facility_groups(action)
    resources_for(FacilityGroup, action)
      .union(FacilityGroup.where(organization: accessible_organizations(action)))
      .includes(:organization)
  end

  def accessible_facilities(action)
    resources_for(Facility, action)
      .union(Facility.where(facility_group: accessible_facility_groups(action)))
      .includes(facility_group: :organization)
  end

  def can?(action, model, record = nil)
    if record&.is_a? ActiveRecord::Relation
      raise ArgumentError, "record should not be an ActiveRecord::Relation."
    end

    case model
      when :facility
        can_access_record?(accessible_facilities(action), record)
      when :organization
        can_access_record?(accessible_organizations(action), record)
      when :facility_group
        can_access_record?(accessible_facility_groups(action), record)
      else
        raise ArgumentError, "Access to #{model} is unsupported."
    end
  end

  def permitted_access_levels
    return LEVELS.keys if bypass?

    LEVELS[user.access_level.to_sym][:grant_access]
  end

  def grant_access(new_user, selected_facility_ids)
    return if selected_facility_ids.blank?
    return if bypass?

    raise NotAuthorizedError unless permitted_access_levels.include?(new_user.access_level.to_sym)

    resources = prepare_grantable_resources(selected_facility_ids)
    # if the user couldn't prepare resources for new_user means they shouldn't have had access to this operation at all
    raise NotAuthorizedError if resources.empty?

    # recreate accesses from scratch to handle deletes/edits/updates seamlessly
    User.transaction do
      new_user.accesses.delete_all
      new_user.accesses.import!(resources)
    end
  end

  def access_tree
    UserAccessTree.new(user)
  end

  private

  def can_access_record?(resources, record)
    return true if bypass?
    return resources.find_by_id(record).present? if record

    resources.exists?
  end

  def resources_for(resource_model, action)
    return resource_model.all if bypass?
    return resource_model.none unless ACTION_TO_LEVEL.fetch(action).include?(user.access_level.to_sym)

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
      if can?(:manage, :organization, org) &&
        (accessible_facilities_in_org[org].to_set == selected_facilities_in_org.to_set)

        resources << {resource_type: Organization.name, resource_id: org.id}
        selected_facilities -= selected_facilities_in_org
      end
    end

    accessible_facilities_in_fg = accessible_facilities(:manage).group_by(&:facility_group)
    selected_facilities.group_by(&:facility_group).each do |fg, selected_facilities_in_fg|
      if can?(:manage, :facility_group, fg) &&
        (accessible_facilities_in_fg[fg].to_set == selected_facilities_in_fg.to_set)

        resources << {resource_type: FacilityGroup.name, resource_id: fg.id}
        selected_facilities -= selected_facilities_in_fg
      end
    end

    selected_facilities.each do |f|
      if can?(:manage, :facility, f)
        resources << {resource_type: Facility.name, resource_id: f.id}
      end
    end

    resources.flatten
  end

  def bypass?
    user.power_user?
  end
end
