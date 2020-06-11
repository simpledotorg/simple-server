class Admin::OrganizationsController < AdminController
  before_action :set_organization, only: [:edit, :update, :destroy]

  def index
    authorize([:manage, Organization])
    @organizations = policy_scope([:manage, Organization]).order(:name)
  end

  def new
    @organization = Organization.new
    authorize([:manage, @organization])
  end

  def edit
  end

  def create
    @organization = Organization.new(organization_params)
    authorize([:manage, @organization])

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
    @organization = Organization.friendly.find(params[:id])
    authorize([:manage, @organization])
  end

  def organization_params
    params.require(:organization).permit(
      :name,
      :description
    )
  end
end
