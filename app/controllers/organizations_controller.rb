class OrganizationsController < AdminController
  def index
    skip_authorization
    @organizations = policy_scope(Organization).order(:name)
  end
end
