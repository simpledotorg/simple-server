class OrganizationsController < AdminController
  include Pagination

  def index
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      current_admin.authorize(:view_reports, :facility)
    else
      authorize(:dashboard, :show?)
    end

    @users_requesting_approval = policy_scope([:manage, :user, User])
      .requested_sync_approval
      .order(updated_at: :desc)

    @users_requesting_approval = paginate(@users_requesting_approval)

    @organizations = if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      current_admin
        .accessible_facility_groups(:view_reports)
        .includes(:organization)
        .flat_map(&:organization)
        .uniq
        .sort_by(&:name)
    else
      policy_scope([:cohort_report, Organization]).order(:name)
    end
  end
end
