class OrganizationsController < AdminController
  def index
    skip_authorization

    @users_requesting_approval = policy_scope(User).requested_sync_approval

    @organizations = policy_scope(Organization).order(:name)
  end
end
