class Admin::FacilitiesController < AdminController
  include FileUploadable
  include Pagination
  include SearchHelper

  before_action :set_facility, only: [:show, :edit, :update, :destroy]
  before_action :set_facility_group, only: [:show, :new, :create, :edit, :update, :destroy]
  before_action :initialize_upload, :validate_file_type, :validate_file_size, :parse_file,
    :validate_facility_rows, if: :file_exists?, only: [:upload]

  skip_after_action :verify_authorized, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  skip_after_action :verify_policy_scoped, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  after_action :verify_access_authorized, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }

  def index
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      current_admin.authorize(:manage, :facility, :access_any)
    else
      authorize([:manage, :facility, Facility])
    end

    if searching?
      facilities = if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
        current_admin.accessible_facilities(:manage).search_by_name(search_query)
      else
        policy_scope([:manage, :facility, Facility]).search_by_name(search_query)
      end

      facility_groups = FacilityGroup.where(facilities: facilities)

      @organizations = Organization.where(facility_groups: facility_groups)
      @facility_groups = facility_groups.group_by(&:organization)
      @facilities = facilities.group_by(&:facility_group)
    elsif Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      accessible_facilities = current_admin.accessible_facilities(:manage)
      visible_facility_groups = current_admin.accessible_facility_groups(:manage)
        .union(FacilityGroup.where(id: accessible_facilities.map(&:facility_group_id).uniq))
      visible_organizations = current_admin.accessible_organizations(:manage)
        .union(Organization.where(id: visible_facility_groups.map(&:organization_id).uniq))
      @organizations = visible_organizations
      @facility_groups = @organizations.map { |organization|
        [organization, visible_facility_groups.where(organization: organization)]
      }.to_h
      @facilities = @facility_groups.values.flatten.map { |facility_group|
        [facility_group, accessible_facilities.where(facility_group: facility_group)]
      }.to_h
    else
      @organizations = policy_scope([:manage, :facility, Organization])
      @facility_groups = @organizations.map { |organization|
        [organization, policy_scope([:manage, :facility, organization.facility_groups])]
      }.to_h
      @facilities = @facility_groups.values.flatten.map { |facility_group|
        [facility_group, policy_scope([:manage, :facility, facility_group.facilities])]
      }.to_h
    end
  end

  def show
  end

  def new
    @facility = new_facility
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      current_admin.authorize(:manage, :facility, :access_record, @facility)
    else
      authorize([:manage, :facility, @facility])
    end
  end

  def edit
  end

  def create
    @facility = new_facility(facility_params)
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      current_admin.authorize(:manage, :facility, :access_record, @facility)
    else
      authorize([:manage, :facility, @facility])
    end

    if @facility.save
      redirect_to [:admin, @facility_group, @facility], notice: "Facility was successfully created."
    else
      render :new
    end
  end

  def update
    if @facility.update(facility_params)
      redirect_to [:admin, @facility_group, @facility], notice: "Facility was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @facility.destroy
    redirect_to admin_facilities_url, notice: "Facility was successfully deleted."
  end

  def upload
    authorize([:manage, :facility, Facility])
    return render :upload, status: :bad_request if @errors.present?

    if @facilities.present?
      ImportFacilitiesJob.perform_later(@facilities)
      flash.now[:notice] = "File upload successful, your facilities will be created shortly."
    end
    render :upload
  end

  private

  def new_facility(attributes = nil)
    @facility_group.facilities.new(attributes).tap do |facility|
      facility.country ||= Rails.application.config.country[:name]
    end
  end

  def set_facility
    @facility = Facility.friendly.find(params[:id])
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      current_admin.authorize(:manage, :facility, :access_record, @facility)
    else
      authorize([:manage, :facility, @facility])
    end
  end

  def set_facility_group
    @facility_group = FacilityGroup.friendly.find(params[:facility_group_id])
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
      :facility_size,
      :latitude,
      :longitude,
      :enable_diabetes_management,
      :monthly_estimated_opd_load,
      :zone,
      :enable_teleconsultation,
      :teleconsultation_phone_number,
      :teleconsultation_isd_code,
      teleconsultation_phone_numbers_attributes: [:isd_code, :phone_number, :_destroy]
    )
  end

  def initialize_upload
    @errors = []
    @file = params.require(:upload_facilities_file)
  end

  def parse_file
    return render :upload, status: :bad_request if @errors.present?

    @file_contents = read_xlsx_or_csv_file(@file)
    @facilities = Facility.parse_facilities(@file_contents)
  end

  def validate_facility_rows
    @errors = Admin::CSV::FacilityValidator.validate(@facilities).errors
  end

  def file_exists?
    params[:upload_facilities_file].present?
  end
end
