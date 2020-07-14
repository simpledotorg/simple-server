class OrganizationsController < AdminController
  include Pagination

  def index
    authorize(:dashboard, :show?)

    @users_requesting_approval = policy_scope([:permission, :manage, User])
      .requested_sync_approval
      .order(updated_at: :desc)

    @users_requesting_approval = paginate(@users_requesting_approval)

    @organizations = policy_scope([:cohort_report, Organization]).order(:name)
  end
end
