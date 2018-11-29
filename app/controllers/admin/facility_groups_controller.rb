class Admin::FacilityGroupsController < AdminController
  before_action :set_facility_group, only: [:show, :edit, :update, :destroy]

  def index
    authorize FacilityGroup
    @facility_groups = FacilityGroup.all.order(:name)
  end

  def show
  end

  def new
    @facility_group = @organization.facility_groups.new
    authorize @facility_group
  end

  def edit
  end

  def create
    @facility_group = @organization.new(facility_params)
    authorize @facility_group

    if @facility_group.save
      redirect_to [:admin, @facility_group], notice: 'FacilityGroup was successfully created.'
    else
      render :new
    end
  end

  def update
    if @facility_group.update(facility_params)
      redirect_to [:admin, @facility_group], notice: 'FacilityGroup was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @facility_group.destroy
    redirect_to admin_organization_facility_groups_url, notice: 'FacilityGroup was successfully deleted.'
  end

  private

  def set_facility_group
    @facility_group= FacilityGroup.find(params[:id])
    authorize @facility_group
  end

  def set_organization
    @organization= Organization.find(params[:organization_id])
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
