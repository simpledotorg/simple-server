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

  def index
    raise Pundit::NotAuthorizedError unless current_admin.can_manage_facilities?(Facility)

    facilities =
      if searching?
        current_admin
          .accessible_facilities(:manage)
          .includes(facility_group: :organization)
          .search_by_name(search_query)
      else
        current_admin
          .accessible_facilities(:manage)
          .includes(facility_group: :organization)
      end

    @organizations = facilities.flat_map(&:organization).uniq
    @facilities = facilities.group_by(&:facility_group)
    @facility_groups = facilities.flat_map(&:facility_group).uniq.compact.group_by(&:organization)
  end

  def show
    authorize_facility
    @admin = current_admin
  end

  def new
    authorize_facility_group
    @facility = new_facility
  end

  def create
    authorize_facility_group
    @facility = new_facility(facility_params)

    if @facility.save
      redirect_to [:admin, @facility_group, @facility], notice: "Facility was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    authorize_facility

    if @facility.update(facility_params)
      redirect_to [:admin, @facility_group, @facility], notice: "Facility was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    authorize_facility_group

    @facility.destroy
    redirect_to admin_facilities_url, notice: "Facility was successfully deleted."
  end

  def upload
    authorize([:upcoming, :manage, FacilityGroup], :allowed?)
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
  end

  def set_facility_group
    @facility_group = FacilityGroup.friendly.find(params[:facility_group_id])
  end

  def authorize_facility
    raise Pundit::NotAuthorizedError unless current_admin.can_manage_facilities?(@facility)
  end

  def authorize_facility_group
    raise Pundit::NotAuthorizedError unless current_admin.can_manage_facility_groups?(@facility_group)
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
