class InviteAdminPresenter < SimpleDelegator
  attr_reader :current_admin

  def initialize(current_admin)
    @current_admin = current_admin
    super
  end

  def access_tree
    display_facilities = ancestor_facilities.map do |ancestor_facility|
      [
        resource_details(ancestor_facility),
        {
          selected: false,
          access: access?(accessible_facilities, ancestor_facility)
        }
      ]
    end.to_h

    display_facility_groups = ancestor_facility_groups.map do |ancestor_fg|
      [
        resource_details(ancestor_fg),
        {
          selected: false,
          access: access?(accessible_facility_groups, ancestor_fg),
          facilities: display_facilities.select { |f, _| parent?(f, ancestor_fg) }
        }
      ]
    end.to_h

    ancestor_organizations.map do |ancestor_org|
      [
        resource_details(ancestor_org),
        {
          selected: false,
          access: access?(accessible_facility_groups, ancestor_org),
          facility_groups: display_facility_groups.select { |fg, _| parent?(fg, ancestor_org) }
        }
      ]
    end.to_h
  end

  private

  def parent?(resource, ancestor)
    resource[:parent_id] == ancestor.id
  end

  def access?(resources, resource)
    resources.map(&:id).include?(resource.id)
  end

  def resource_details(resource)
    resource.slice(:id, :name, :parent_id)
  end

  def ancestor_organizations
    ancestor_facility_groups.flat_map(&:organization).uniq
  end

  def ancestor_facilities
    ancestor_facility_groups.flat_map(&:facilities).uniq
  end

  def ancestor_facility_groups
    accessible_facilities.map(&:facility_group).uniq
  end

  def accessible_facilities
    @accessible_facilities ||= current_admin.accessible_facilities(:manage)
  end

  def accessible_facility_groups
    @accessible_facility_groups ||= current_admin.accessible_facility_groups(:manage)
  end

  def accessible_organizations
    @accessible_organizations ||= current_admin.accessible_organizations(:manage)
  end
end
