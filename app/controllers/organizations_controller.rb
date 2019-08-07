class OrganizationsController < AdminController
  include Pagination

  def index
    skip_authorization

    @users_requesting_approval = policy_scope(User)
                                   .requested_sync_approval
                                   .order(device_created_at: :asc)

    @users_requesting_approval = paginate(@users_requesting_approval)

    @organizations = policy_scope(Organization).order(:name)
  end
end
