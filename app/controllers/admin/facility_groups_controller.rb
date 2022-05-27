class Admin::FacilityGroupsController < AdminController
  before_action :set_facility_group, only: [:show, :edit, :update, :destroy]
  before_action :set_organizations, only: [:new, :edit, :update, :create]
  before_action :set_protocols, only: [:new, :edit, :update, :create]
  before_action :set_available_states, only: [:new, :create, :edit, :update]
  before_action :set_blocks, only: [:edit, :update]

  def show
    @facilities = @facility_group.facilities.order(:name)
    @users = @facility_group.users.order(:full_name)
  end

  def new
    @facility_group = FacilityGroup.new
    authorize { current_admin.accessible_organizations(:manage).any? }
  end

  def edit
  end

  def create
    @facility_group = FacilityGroup.new(facility_group_params)
    authorize { current_admin.accessible_organizations(:manage).find(@facility_group.organization.id) }

    if create_facility_group
      redirect_to admin_facilities_url, notice: "FacilityGroup was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if update_facility_group
      redirect_to admin_facilities_url, notice: "Facility group was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @facility_group.discardable?
      discard_facility_group
      redirect_to admin_facilities_url, notice: "FacilityGroup was successfully deleted."
    else
      redirect_to admin_facilities_url, alert: "FacilityGroup cannot be deleted, please move patient data and try again."
    end
  end

  private

  def discard_facility_group
    state_region = @facility_group.region.state_region
    ActiveRecord::Base.transaction do
      @facility_group.discard
      state_region.recalculate_state_population!
    end
  end

  # Do all the things for create inside a single transaction. Note that we explicitly return true if everything
  # succeeds so we don't need to rely on return values from the model layer.
  def create_facility_group
    ActiveRecord::Base.transaction do
      @facility_group.create_state_region!
      @facility_group.save!
      @facility_group.sync_block_regions
      @facility_group.toggle_diabetes_management
      true
    end
  rescue ActiveRecord::RecordInvalid => e
    Sentry.capture_exception(e)
  end

  # Do all the things for update inside a single transaction. Note that we explicitly return true if everything
  # succeeds so we don't need to rely on return values from the model layer.
  def update_facility_group
    ActiveRecord::Base.transaction do
      @facility_group.update!(facility_group_params.except(:state))
      @facility_group.sync_block_regions
      @facility_group.toggle_diabetes_management
      true
    end
  rescue ActiveRecord::RecordInvalid => e
    Sentry.capture_exception(e)
  end

  def set_organizations
    # include the facility group's organization along with the ones you can access
    @organizations = current_admin.accessible_organizations(:manage).presence || [@facility_group.organization]
  end

  def set_protocols
    @protocols = Protocol.all
  end

  def set_facility_group
    @facility_group = authorize { current_admin.accessible_facility_groups(:manage).friendly.find(params[:id]) }
  end

  def set_available_states
    @available_states = CountryConfig.current[:states]
  end

  def set_blocks
    district_region = Region.find_by(source: @facility_group)
    @blocks = district_region&.block_regions&.order(:name) || []
  end

  def facility_group_params
    params.require(:facility_group).permit(
      :organization_id,
      :name,
      :state,
      :description,
      :protocol_id,
      :enable_diabetes_management,
      :district_estimated_population,
      :district_estimated_diabetes_population,
      new_block_names: [],
      remove_block_ids: []
    )
  end
end
