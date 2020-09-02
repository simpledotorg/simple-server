class Admin::OrganizationsController < AdminController
  before_action :set_organization, only: [:edit, :update, :destroy]

  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  after_action :verify_authorization_attempted

  def index
    authorize1 { current_admin.power_user? }
    @organizations = current_admin.accessible_organizations(:manage).order(:name)
  end

  def new
    authorize1 { current_admin.power_user? }
    @organization = Organization.new
  end

  def edit
  end

  def create
    authorize1 { current_admin.power_user? }
    @organization = Organization.new(organization_params)

    if @organization.save
      redirect_to admin_organizations_url, notice: "Organization was successfully created."
    else
      render :new
    end
  end

  def update
    if @organization.update(organization_params)
      redirect_to admin_organizations_url, notice: "Organization was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @organization.destroy
    redirect_to admin_organizations_url, notice: "Organization was successfully deleted."
  end

  private

  def set_organization
    @organization = authorize1 { current_admin.accessible_organizations(:manage).friendly.find(params[:id]) }
  end

  def organization_params
    params.require(:organization).permit(
      :name,
      :description
    )
  end
end
