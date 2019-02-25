class Admin::FacilityGroupsController < AdminController
  before_action :set_organization, only: [:index, :show, :edit, :update, :destroy]
  before_action :set_facility_group, only: [:show, :edit, :update, :destroy]
  before_action :set_protocols, only: [:new, :edit]

  def index
    authorize FacilityGroup
    @facility_groups = policy_scope(FacilityGroup).order(:name)
  end

  def show
  end

  def new
    @organization = Organization.friendly.find(params[:organization_id])
    @facility_group = @organization.facility_groups.new
    authorize @facility_group
  end

  def edit
  end

  def create
    @organization = Organization.friendly.find(params[:organization_id])
    @facility_group = @organization.facility_groups.new(facility_group_params)
    authorize @facility_group

    if @facility_group.save
      redirect_to [:admin, @organization], notice: 'FacilityGroup was successfully created.'
    else
      render :new
    end
  end

  def update
    if @facility_group.update(facility_group_params)
      redirect_to [:admin, @organization], notice: 'FacilityGroup was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @facility_group.destroy
    redirect_to admin_organization_facility_groups_url(@organization), notice: 'FacilityGroup was successfully deleted.'
  end

  private

  def set_protocols
    @protocols = Protocol.all
  end

  def set_facility_group
    @facility_group= FacilityGroup.friendly.find(params[:id])
    authorize @facility_group
  end

  def set_organization
    @organization = Organization.friendly.find(params[:organization_id])
    authorize @organization
  end

  def facility_group_params
    params.require(:facility_group).permit(
      :name,
      :description,
      :protocol_id,
      facility_ids: []
    )
  end
end
