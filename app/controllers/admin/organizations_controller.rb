class Admin::OrganizationsController < AdminController
  before_action :set_facility, only: [:show, :edit, :update, :destroy]

  def index
    authorize Organization
    @organizations = Organization.all.order(:name)
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
    @organization = Organization.new(facility_params)
    authorize @organization

    if @organization.save
      redirect_to [:admin, @organization], notice: 'Organization was successfully created.'
    else
      render :new
    end
  end

  def update
    if @organization.update(facility_params)
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

  def set_facility
    @organization = Organization.find(params[:id])
    authorize @organization
  end

  def facility_params
    params.require(:facility).permit(
      :name,
      :street_address,
      :village_or_colony,
      :district,
      :state,
      :country,
      :pin,
      :facility_type,
      :latitude,
      :longitude
    )
  end
end
