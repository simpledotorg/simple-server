class Admin::FacilityGroupsController < AdminController
  before_action :set_organizations, only: [:new, :edit, :update, :create]
  before_action :set_facility_group, only: [:edit, :update, :destroy]
  before_action :set_protocols, only: [:new, :edit, :update, :create]
  before_action :authorize_facility_group, only: [:edit, :update, :destroy]

  def new
    @facility_group = FacilityGroup.new
    authorize([:upcoming, :manage, Organization], :allowed?)
  end

  def edit
  end

  def create
    @facility_group = FacilityGroup.new(facility_group_params)
    authorize([:upcoming, :manage, @facility_group.organization], :allowed?)

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
    @organizations = policy_scope([:upcoming, :manage, Organization])
  end

  def set_protocols
    @protocols = Protocol.all
  end

  def set_facility_group
    @facility_group = FacilityGroup.friendly.find(params[:id])
  end

  def authorize_facility_group
    authorize([:upcoming, :manage, @facility_group], :allowed?)
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
