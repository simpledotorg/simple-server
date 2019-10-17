class OrganizationsController < AdminController
  include Pagination

  def index
    authorize([:cohort_report, Organization])

    @users_requesting_approval = policy_scope(User)
                                   .requested_sync_approval
                                   .order(updated_at: :desc)

    @users_requesting_approval = paginate(@users_requesting_approval)

    @organizations = policy_scope([:cohort_report, Organization]).order(:name)
  end
end
