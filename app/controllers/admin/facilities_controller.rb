class Admin::FacilitiesController < AdminController
  include FileUploadable
  include Pagination
  include SearchHelper

  before_action :set_facility, only: [:show, :edit, :update, :destroy]
  before_action :set_facility_group, only: [:show, :new, :create, :edit, :update, :destroy]
  before_action :authorize_facility, only: [:show, :edit, :update, :destroy]
  before_action :authorize_facility_group, only: [:new, :create]
  before_action :initialize_upload, :validate_file_type, :validate_file_size, :parse_file,
    :validate_facility_rows, if: :file_exists?, only: [:upload]

  def index
    authorize([:upcoming, :manage, Facility.all], :allowed?)

    if searching?
      facilities = policy_scope([:upcoming, :manage, Facility.all]).search_by_name(search_query)
      facility_groups = FacilityGroup.where(facilities: facilities)

      @organizations = Organization.where(facility_groups: facility_groups)
      @facility_groups = facility_groups.group_by(&:organization)
      @facilities = facilities.group_by(&:facility_group)
    else
      @organizations = policy_scope([:upcoming, :manage, Organization.all])
      @facility_groups = @organizations.map { |organization|
        [organization, policy_scope([:upcoming, :manage, organization.facility_groups])]
      }.to_h
      @facilities = @facility_groups.values.flatten.map { |facility_group|
        [facility_group, policy_scope([:upcoming, :manage, facility_group.facilities])]
      }.to_h
    end
  end

  def show
  end

  def new
    @facility = new_facility
  end

  def create
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
    authorize([:upcoming, :manage, FacilityGroup.all], :allowed?)
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

  def authorize_facility
    authorize([:upcoming, :manage, @facility], :allowed?)
  end

  def authorize_facility_group
    authorize([:upcoming, :manage, @facility_group], :allowed?)
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
