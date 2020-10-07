class OrganizationsController < AdminController
  include Pagination

  def index
    @accessible_facilities = current_admin.accessible_facilities(:view_reports)
    authorize { @accessible_facilities.any? }

    users = current_admin.accessible_users(:manage)

    @users_requesting_approval = users
      .requested_sync_approval
      .order(updated_at: :desc)

    @users_requesting_approval = paginate(users
                                            .requested_sync_approval
                                            .order(updated_at: :desc))

    @organizations = @accessible_facilities
      .includes(facility_group: :organization)
      .flat_map(&:organization)
      .uniq
      .compact
      .sort_by(&:name)
  end
end
