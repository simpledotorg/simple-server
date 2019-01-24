class Admin::OrganizationsController < AdminController
  before_action :set_organization, only: [:show, :edit, :update, :destroy]

  def index
    authorize Organization
    @organizations = policy_scope(Organization).order(:name)
  end

  def show
  end

  def new
    @organization = Organization.new
    authorize @organization
  end

  def edit
  end

  def create
    @organization = Organization.new(organization_params)
    authorize @organization

    if @organization.save
      redirect_to [:admin, @organization], notice: 'Organization was successfully created.'
    else
      render :new
    end
  end

  def update
    if @organization.update(organization_params)
      redirect_to [:admin, @organization], notice: 'Organization was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @organization.destroy
    redirect_to admin_organizations_url, notice: 'Organization was successfully deleted.'
  end

  private

  def set_organization
    @organization = Organization.friendly.find(params[:id])
    authorize @organization
  end

  def organization_params
    params.require(:organization).permit(
      :name,
      :description
    )
  end
end
