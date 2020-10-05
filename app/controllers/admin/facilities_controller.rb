class Admin::FacilitiesController < AdminController
  include FileUploadable
  include Pagination
  include SearchHelper

  before_action :set_facility, only: [:show, :edit, :update, :destroy]
  before_action :set_facility_group, only: [:show, :new, :create, :edit, :update, :destroy]

  before_action :initialize_upload, :validate_file_type, :validate_file_size, :parse_file,
    :validate_facility_rows, if: :file_exists?, only: [:upload]

  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  after_action :verify_authorization_attempted

  def index
    authorize_v2 do
      current_admin.accessible_facilities(:manage).any? ||
        current_admin.accessible_facility_groups(:manage).any? ||
        current_admin.accessible_organizations(:manage).any?
    end

    accessible_facilities = current_admin.accessible_facilities(:manage)

    if searching?
      facilities = accessible_facilities.search_by_name(search_query)
      facility_groups = FacilityGroup.where(facilities: facilities)

      @organizations = Organization.where(facility_groups: facility_groups)
      @facility_groups = facility_groups.group_by(&:organization)
      @facilities = facilities.group_by(&:facility_group)
    else

      @facilities = accessible_facilities.group_by(&:facility_group)

      visible_facility_groups =
        accessible_facilities
          .map(&:facility_group)
          .concat(current_admin.accessible_facility_groups(:manage).to_a)
          .uniq
          .compact
      @facility_groups = visible_facility_groups.group_by(&:organization)

      @organizations =
        visible_facility_groups
          .map(&:organization)
          .concat(current_admin.accessible_organizations(:manage).to_a)
          .uniq
          .compact
    end
  end

  def show
    @facility_users = current_admin
        .accessible_users(:manage)      
        .where(phone_number_authentications: {registration_facility_id: @facility})
  end

  def new
    @facility = new_facility

    authorize_v2 { current_admin.accessible_facility_groups(:manage).find(@facility.facility_group.id) }
  end

  def edit
  end

  def create
    @facility = new_facility(facility_params)

    authorize_v2 { current_admin.accessible_facility_groups(:manage).find(@facility.facility_group.id) }

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
    if @facility.discardable?
      @facility.discard
      redirect_to admin_facilities_url, notice: "Facility was successfully deleted."
    else
      redirect_to admin_facilities_url, notice: "Facility cannot be deleted, please move patient data and try again."
    end
  end

  def upload
    authorize_v2 { current_admin.accessible_facility_groups(:manage).any? }

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
    @facility = authorize_v2 { current_admin.accessible_facilities(:manage).friendly.find(params[:id]) }
  end

  def set_facility_group
    @facility_group = current_admin.accessible_facility_groups(:manage).friendly.find(params[:facility_group_id])
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
      teleconsultation_medical_officer_ids: [],
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
