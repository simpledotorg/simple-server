class Admin::FacilityGroupsController < AdminController
  before_action :set_facility_group, only: [:show, :edit, :update, :destroy]
  before_action :set_organizations, only: [:new, :edit, :update, :create]
  before_action :set_protocols, only: [:new, :edit, :update, :create]

  skip_after_action :verify_authorized, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  skip_after_action :verify_policy_scoped, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  after_action :verify_authorization_attempted, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }

  def show
    @facilities = @facility_group.facilities.order(:name)
    @users = @facility_group.users.order(:full_name)
  end

  def new
    @facility_group = FacilityGroup.new

    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      authorize1 { current_admin.accessible_organizations(:manage).any? }
    else
      authorize([:manage, @facility_group])
    end
  end

  def edit
  end

  def create
    @facility_group = FacilityGroup.new(facility_group_params)

    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      authorize1 { current_admin.accessible_organizations(:manage).find(@facility_group.organization.id) }
    else
      authorize([:manage, @facility_group])
    end

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
    @organizations =
      if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
        # include the facility group's organization along with the ones you can access
        current_admin.accessible_organizations(:manage).presence || [@facility_group.organization]
      else
        policy_scope([:manage, :facility, Organization])
      end
  end

  def set_protocols
    @protocols = Protocol.all
  end

  def set_facility_group
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      @facility_group = authorize1 { current_admin.accessible_facility_groups(:manage).friendly.find(params[:id]) }
    else
      @facility_group = FacilityGroup.friendly.find(params[:id])
      authorize([:manage, @facility_group])
    end
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
