class Admin::FacilityGroupsController < AdminController
  before_action :set_facility_group, only: [:show, :edit, :update, :destroy]
  before_action :set_organizations, only: [:new, :edit]
  before_action :set_protocols, only: [:new, :edit]

  def index
    authorize FacilityGroup
    @facility_groups = policy_scope(FacilityGroup).order(:name)
  end

  def show
    @facilities = @facility_group.facilities.order(:name)
    @users = @facility_group.users.order(:full_name)
  end

  def new
    @facility_group = FacilityGroup.new
    authorize @facility_group
  end

  def edit
  end

  def create
    @facility_group = FacilityGroup.new(facility_group_params)
    authorize @facility_group

    if @facility_group.save
      redirect_to admin_facilities_url, notice: 'FacilityGroup was successfully created.'
    else
      render :new
    end
  end

  def update
    if @facility_group.update(facility_group_params)
      redirect_to admin_facilities_url, notice: 'FacilityGroup was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    if @facility_group.discard
      redirect_to admin_facilities_url, notice: 'FacilityGroup was successfully deleted.'
    else
      redirect_to admin_facilities_url, alert: 'FacilityGroup could not be deleted'
    end
  end

  def upload
    authorize FacilityGroup
    if params[:facilities_csv]
      redirect_to admin_facilities_url, notice: "File uploaded #{params[:facilities_csv].original_filename}"
    else
      render :upload
    end
  end

  private

  def set_organizations
    @organizations = policy_scope(Organization)
  end

  def set_protocols
    @protocols = Protocol.all
  end

  def set_facility_group
    @facility_group = FacilityGroup.friendly.find(params[:id])
    authorize @facility_group
  end

  def facility_group_params
    params.require(:facility_group).permit(
      :organization_id,
      :name,
      :description,
      :protocol_id,
      facility_ids: []
    )
  end
end
