class Admin::FacilityGroupsController < AdminController
  before_action :set_facility_group, only: [:show, :edit, :update, :destroy]
  before_action :set_organizations, only: [:new, :edit, :update, :create]
  before_action :set_protocols, only: [:new, :edit, :update, :create]
  before_action :set_available_states, only: [:new, :create, :edit, :update], if: -> { Flipper.enabled?(:regions_prep) }
  before_action :set_blocks, only: [:edit, :update], if: -> { Flipper.enabled?(:regions_prep) }

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

    if create_successful?
      redirect_to admin_facilities_url, notice: "FacilityGroup was successfully created."
    else
      render :new, status: :bad_request
    end
  end

  def update
    # hack to work around how we are handling state updates on the facility group model
    @facility_group.state = nil
    if update_successful?
      redirect_to admin_facilities_url, notice: "FacilityGroup was successfully updated."
    else
      render :edit, status: :bad_request
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
    @facility_group = authorize { current_admin.accessible_facility_groups(:manage).friendly.find(params[:id]) }
  end

  def set_available_states
    @available_states = CountryConfig.current[:states]
  end

  def set_blocks
    district_region = Region.find_by(source: @facility_group)
    @blocks = district_region&.block_regions&.order(:name) || []
  end

  def wrap_in_transaction
    ActiveRecord::Base.transaction do
      yield
    end
  end

  def facility_group_params
    params.require(:facility_group).permit(
      :organization_id,
      :name,
      :state,
      :description,
      :protocol_id,
      :enable_diabetes_management,
      new_block_names: [],
      remove_block_ids: []
    )
  end

  def create_successful?
    CreateFacilityGroup.new(@facility_group).create
  end

  def update_successful?
    params = facility_group_params.except(:state)
    CreateFacilityGroup.new(@facility_group, params: params).update
  end

  class CreateFacilityGroup
    attr_reader :facility_group
    attr_reader :state_name

    def initialize(facility_group, params: nil)
      @facility_group = facility_group
      @params = params
      @state_name = @facility_group.state
    end

    delegate :transaction, to: ActiveRecord::Base

    def create
      transaction do
        create_state_region
        if facility_group.save && facility_group.toggle_diabetes_management
          create_block_regions
          remove_block_regions
          true
        end
      end
    end

    def update
      transaction do
        if facility_group.update(@params) && facility_group.toggle_diabetes_management
          create_block_regions
          remove_block_regions
          true
        end
      end
    end

    def create_state_region
      return unless Flipper.enabled?(:regions_prep)
      return if facility_group.state_region || state_name.blank?

      Region.state_regions.create!(name: state_name, reparent_to: facility_group.organization.region)
    end

    def create_block_regions
      return unless Flipper.enabled?(:regions_prep)
      return if facility_group.new_block_names.blank?

      facility_group.new_block_names.map { |name|
        Region.block_regions.create!(name: name, reparent_to: facility_group.region)
      }
    end

    def remove_block_regions
      return unless Flipper.enabled?(:regions_prep)
      return if facility_group.remove_block_ids.blank?

      facility_group.remove_block_ids.map { |id|
        next unless Region.find(id)
        next unless Region.find(id).children.empty?

        Region.destroy(id)
      }
    end
  end

end
