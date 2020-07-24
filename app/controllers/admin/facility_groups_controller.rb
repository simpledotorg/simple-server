class Admin::FacilityGroupsController < AdminController
  before_action :set_organizations, only: [:new, :edit, :update, :create]
  before_action :set_facility_group, only: [:edit, :update, :destroy]
  before_action :set_protocols, only: [:new, :edit, :update, :create]

  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def new
    @facility_group = FacilityGroup.new
    raise Pundit::NotAuthorizedError unless current_admin.can_manage_organizations?(Organization)
  end

  def edit
    authorize_facility_group
  end

  def create
    @facility_group = FacilityGroup.new(facility_group_params)
    authorize_organization

    if @facility_group.save && @facility_group.toggle_diabetes_management
      redirect_to admin_facilities_url, notice: "FacilityGroup was successfully created."
    else
      render :new
    end
  end

  def update
    authorize_facility_group

    if @facility_group.update(facility_group_params) && @facility_group.toggle_diabetes_management
      redirect_to admin_facilities_url, notice: "FacilityGroup was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    authorize_organization

    if @facility_group.discard
      redirect_to admin_facilities_url, notice: "FacilityGroup was successfully deleted."
    else
      redirect_to admin_facilities_url, alert: "FacilityGroup could not be deleted"
    end
  end

  private

  def set_organizations
    @organizations = current_admin.accessible_organizations(:manage)
  end

  def set_protocols
    @protocols = Protocol.all
  end

  def set_facility_group
    @facility_group = FacilityGroup.friendly.find(params[:id])
  end

  def authorize_facility_group
    raise Pundit::NotAuthorizedError unless current_admin.can_manage_facility_groups?(@facility_group)
  end

  def authorize_organization
    raise Pundit::NotAuthorizedError unless current_admin.can_manage_organizations?(@facility_group.organization)
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
