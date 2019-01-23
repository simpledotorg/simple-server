class OrganizationsController < AdminController
  def index
    authorize(Organization)
    @organizations = policy_scope(Organization).order(:name).includes(:facility_groups)
  end
end

