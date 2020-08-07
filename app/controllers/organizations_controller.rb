class OrganizationsController < AdminController
  include Pagination
  skip_after_action :verify_authorized

  def index
    authorize(:dashboard, :show?)
    current_admin.can?(:view_reports, :facility_group)

    @users_requesting_approval = policy_scope([:manage, :user, User])
                                   .requested_sync_approval
                                   .order(updated_at: :desc)

    @users_requesting_approval = paginate(@users_requesting_approval)

    @organizations = current_admin
                       .accessible_facility_groups(:view_reports)
                       .includes(:organization)
                       .flat_map(&:organization)
                       .uniq
                       .sort_by(&:name)
  end
end
