class Admin::FacilityGroupsController < AdminController
  before_action :set_facility_group, only: [:show, :edit, :update, :destroy]
  before_action :set_organizations, only: [:new, :edit, :update, :create]
  before_action :set_protocols, only: [:new, :edit, :update, :create]

  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  after_action :verify_authorization_attempted

  def show
    @facilities = @facility_group.facilities.order(:name)
    @users = @facility_group.users.order(:full_name)
  end

  def new
    @facility_group = FacilityGroup.new

    authorize_v2 { current_admin.accessible_organizations(:manage).any? }
  end

  def edit
  end

  def create
    @facility_group = FacilityGroup.new(facility_group_params)

    authorize_v2 { current_admin.accessible_organizations(:manage).find(@facility_group.organization.id) }

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
    if @facility_group.discardable?
      @facility_group.discard
      redirect_to admin_facilities_url, notice: "FacilityGroup was successfully deleted."
    else
      redirect_to admin_facilities_url, alert: "FacilityGroup cannot be deleted, please move patient data and try again."
    end
  end

  private

  def set_organizations
    # include the facility group's organization along with the ones you can access
    @organizations = current_admin.accessible_organizations(:manage).presence || [@facility_group.organization]
  end

  def set_protocols
    @protocols = Protocol.all
  end

  def set_facility_group
    @facility_group = authorize_v2 { current_admin.accessible_facility_groups(:manage).friendly.find(params[:id]) }
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
