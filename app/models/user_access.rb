class UserAccess < Struct.new(:user)
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

  ACTION_TO_LEVEL = {
    manage_overdue_list: [:manager, :viewer_all, :call_center],
    view_reports: [:manager, :viewer_all, :viewer_reports_only],
    view_pii: [:manager, :viewer_all],
    manage: [:manager]
  }.freeze

  VALID_OPERATIONS = [:access_record, :access_any, :create]

  def accessible_organizations(action)
    resources_for(Organization, action)
  end

  def accessible_facility_groups(action)
    resources_for(FacilityGroup, action)
      .or(FacilityGroup.where(organization: accessible_organizations(action)))
  end

  def accessible_facilities(action)
    resources_for(Facility, action)
      .or(Facility.where(facility_group: accessible_facility_groups(action)))
  end

  def can?(action, model, operation, record = nil)
    raise ArgumentError, "record should not be an ActiveRecord::Relation." if record&.is_a? ActiveRecord::Relation
    raise ArgumentError, "#{operation} is not a supported operation." unless operation.in? VALID_OPERATIONS

    case model
    when :facility
      can_act_on_facility?(action, operation, record)
    when :facility_group
      can_act_on_facility_group?(action, operation, record)
    when :organization
      can_act_on_organization?(action, operation, record)
    else
      raise ArgumentError, "Access to #{model} is unsupported."
    end
  end

  def authorize(action, model, operation, record = nil)
    RequestStore.store[:access_authorized] = true
    raise NotAuthorizedError, self.class unless can?(action, model, operation, record)
  end

  def permitted_access_levels
    return LEVELS.keys if user.power_user?

    LEVELS[user.access_level.to_sym][:grant_access]
  end

  def grant_access(new_user, selected_facility_ids)
    return if selected_facility_ids.blank?
    raise NotAuthorizedError unless permitted_access_levels.include?(new_user.access_level.to_sym)

    resources = prepare_access_resources(selected_facility_ids)
    # if the user couldn't prepare resources for new_user means they shouldn't have had access to this operation at all
    raise NotAuthorizedError if resources.empty?

    # recreate accesses from scratch to handle deletes/edits/updates seamlessly
    User.transaction do
      new_user.accesses.delete_all
      new_user.accesses.create!(resources)
    end
  end

  def access_tree(action)
    facilities = accessible_facilities(action).includes(facility_group: :organization)

    facility_tree =
      facilities
        .map { |facility| [facility, {can_access: true}] }
        .to_h

    facility_group_tree =
      facilities
        .map(&:facility_group)
        .map { |fg|
          facilities_in_facility_group =
            facility_tree.select { |facility, _| facility.facility_group == fg }

          [fg,
            {
              can_access: can?(action, :facility_group, fg),
              facilities: facilities_in_facility_group,
              total_facilities: fg.facilities.size
            }]
        }
        .to_h

    organization_tree =
      facilities
        .map(&:facility_group)
        .map(&:organization)
        .map { |org|
          facility_groups_in_org =
            facility_group_tree.select { |facility_group, _| facility_group.organization == org }

          [org,
            {
              can_access: can?(action, :organization, org),
              facility_groups: facility_groups_in_org,
              total_facility_groups: org.facility_groups.size
            }]
        }
        .to_h

    {organizations: organization_tree}
  end

  private

  def can_access_record?(resources, record)
    return true if user.power_user?
    return resources.find_by_id(record).present? if record

    resources.exists?
  end

  def can_act_on_facility?(action, operation, record)
    case operation
    when :access_record
      can_access_record?(accessible_facilities(action), record)
    when :access_any
      accessible_facilities(action).exists? ||
        accessible_facility_groups(action).exists? ||
        accessible_organizations(action).exists?
    when :create
      accessible_facility_groups(:manage)&.find_by_id(record.facility_group_id).present?
    else
      raise ArgumentError, "#{operation} is unsupported."
    end
  end

  def can_act_on_facility_group?(action, operation, record)
    case operation
    when :access_record
      can_access_record?(accessible_facility_groups(action), record)
    when :access_any
      accessible_facility_groups(action).exists? ||
        accessible_organizations(action).exists?
    when :create
      accessible_organizations(:manage)&.find_by_id(record.organization_id).present?
    else
      raise ArgumentError, "#{operation} is unsupported."
    end
  end

  def can_act_on_organization?(action, operation, record)
    case operation
    when :access_record
      can_access_record?(accessible_organizations(action), record)
    when :access_any
      accessible_organizations(action).exists?
    when :create
      user.power_user?
    else
      raise ArgumentError, "#{operation} is unsupported."
    end
  end

  def resources_for(resource_model, action)
    return resource_model.all if user.power_user?
    return resource_model.none unless ACTION_TO_LEVEL.fetch(action).include?(user.access_level.to_sym)

    resource_ids =
      user
        .accesses
        .where(resource_type: resource_model.to_s)
        .map(&:resource_id)

    resource_model.where(id: resource_ids)
  end

  def prepare_access_resources(selected_facility_ids)
    selected_facilities = Facility.where(id: selected_facility_ids)
    resources = []

    selected_facilities.group_by(&:organization).each do |org, selected_facilities_in_org|
      if can?(:manage, :organization, org) && org.facilities == selected_facilities_in_org
        resources << {resource: org}
        selected_facilities -= selected_facilities_in_org
      end
    end

    selected_facilities.group_by(&:facility_group).each do |fg, selected_facilities_in_fg|
      if can?(:manage, :facility_group, fg) && fg.facilities == selected_facilities_in_fg
        resources << {resource: fg}
        selected_facilities -= selected_facilities_in_fg
      end
    end

    selected_facilities.each do |f|
      resources << {resource: f} if can?(:manage, :facility, f)
    end

    resources.flatten
  end
end
