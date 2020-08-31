class OrganizationsController < AdminController
  include Pagination

  skip_after_action :verify_authorized, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  after_action :verify_access_authorized, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }

  def index
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      current_admin.authorize(:view_reports, :facility, :access_any)
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
