class OrganizationsController < AdminController
  def index
    skip_authorization

    @users_requesting_approval = policy_scope(User).requested_sync_approval

    @organizations = policy_scope(Organization).order(:name)

    @img_for_header = SimpleServerEnvironmentHelper::img_for_environment
    @alt_for_img = SimpleServerEnvironmentHelper::alt_for_environment
  end
end
