require "ostruct"

class InviteAdminPresenter < SimpleDelegator
  attr_reader :current_admin

  def initialize(current_admin)
    @current_admin = current_admin
    super
  end

  def access_tree
    display_facilities = ancestor_facilities.map { |ancestor_facility|
      [
        ancestor_facility.id,
        {
          name: ancestor_facility.name,
          parents: [ancestor_facility.parent_id, ancestor_facility.facility_group.parent_id],
          selected: false,
          access: access?(accessible_facilities, ancestor_facility)
        }
      ]
    }

    display_facility_groups = ancestor_facility_groups.map { |ancestor_fg|
      facilities = display_facilities.to_h.select { |_, f_data| parent?(ancestor_fg, f_data) }

      [
        ancestor_fg.id,
        {
          name: ancestor_fg.name,
          parents: [ancestor_fg.parent_id, ancestor_fg.organization.parent_id],
          selected: false,
          access: access?(accessible_facility_groups, ancestor_fg),
          access_count: facilities.select { |_f, v| v[:access] }.count,
          total_count: facilities.count,
          facilities: facilities
        }
      ]
    }

    display_organizations = ancestor_organizations.map do |ancestor_org|
      facility_groups = display_facility_groups.to_h.select { |_, fg_data| parent?(ancestor_org, fg_data) }
      [
        ancestor_org.id,
        {
          name: ancestor_org.name,
          parents: [ancestor_org.parent_id],
          selected: false,
          access: access?(accessible_facility_groups, ancestor_org),
          access_count: facility_groups.select { |_fg, v| v[:access] }.count,
          total_count: facility_groups.count,
          facility_groups: facility_groups
        }
      ]
    end

    {organizations: display_organizations.to_h}
  end

  private

  def parent?(ancestor, resource)
    ancestor.id == resource[:parents].first
  end

  def access?(resources, resource)
    resources.map(&:id).include?(resource.id)
  end

  def ancestor_facilities
    ancestor_facility_groups.flat_map(&:facilities).uniq
  end

  def ancestor_facility_groups
    accessible_facilities.map(&:facility_group).uniq
  end

  def ancestor_organizations
    ancestor_facility_groups.flat_map(&:organization).uniq
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
