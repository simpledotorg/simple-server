class Admin::FacilityGroupsController < AdminController
  before_action :set_organizations, only: [:new, :edit]
  before_action :set_facility_group, only: [:show, :edit, :update, :destroy]
  before_action :set_protocols, only: [:new, :edit]

  def index
    authorize([:manage, FacilityGroup])
    @facility_groups = policy_scope([:manage, FacilityGroup]).order(:name)
  end

  def show
    @facilities = @facility_group.facilities.order(:name)
    @users = @facility_group.users.order(:full_name)
  end

  def new
    @facility_group = FacilityGroup.new
    authorize([:manage, @facility_group])
  end

  def edit
  end

  def create
    @facility_group = FacilityGroup.new(facility_group_params)
    authorize([:manage, @facility_group])

    if @facility_group.save && @facility_group.toggle_diabetes_management
      redirect_to admin_facilities_url, notice: "FacilityGroup was successfully created."
    else
      render :new
    end
  end

  def update
    if @facility_group.update(facility_group_params) && @facility_group.toggle_diabetes_management
      redirect_to admin_facilities_url, notice: "FacilityGroup was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    if @facility_group.discard
      redirect_to admin_facilities_url, notice: "FacilityGroup was successfully deleted."
    else
      redirect_to admin_facilities_url, alert: "FacilityGroup could not be deleted"
    end
  end

  private

  def set_organizations
    @organizations = policy_scope([:manage, :facility, Organization])
  end

  def set_protocols
    @protocols = Protocol.all
  end

  def set_facility_group
    @facility_group = FacilityGroup.friendly.find(params[:id])
    authorize([:manage, @facility_group])
  end

  def facility_group_params
    params.require(:facility_group).permit(
      :organization_id,
      :name,
      :description,
      :protocol_id,
      :enable_diabetes_management,
      facility_ids: []
    )
  end

  def enable_diabetes_management
    params[:enable_diabetes_management]
  end
end
