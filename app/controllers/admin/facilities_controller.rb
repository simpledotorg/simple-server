class Admin::FacilitiesController < AdminController
  include FileUploadable
  include Pagination
  include SearchHelper

  before_action :set_facility, only: [:show, :edit, :update, :destroy]
  before_action :set_facility_group, only: [:show, :new, :create, :edit, :update, :destroy]
  before_action :set_available_zones, only: [:new, :create, :edit, :update]

  def index
    authorize do
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
    respond_to do |format|
      format.html
      format.csv { render plain: FacilityRegionCsv.to_csv(accessible_facilities.eager_load(:business_identifiers, :region)) }
    end
  end

  def show
    @facility_users = current_admin
      .accessible_users(:manage)
      .where(phone_number_authentications: {registration_facility_id: @facility})
  end

  def new
    @facility = new_facility

    authorize { current_admin.accessible_facility_groups(:manage).find(@facility.facility_group.id) }
  end

  def edit
  end

  def create
    @facility = new_facility(facility_params)

    authorize { current_admin.accessible_facility_groups(:manage).find(@facility.facility_group.id) }

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
    authorize { current_admin.accessible_facility_groups(:manage).any? }

    if file_exists?
      initialize_upload

      validate_file_type
      validate_file_size
      return render :upload, status: :bad_request if @errors.present?

      parse_file
      return render :upload, status: :bad_request if @errors.present?
    end

    if @facilities.present?
      ImportFacilitiesJob.perform_later(@facilities)
      flash.now[:notice] = "File upload successful, your facilities will be created shortly."
    end

    render :upload
  end

  private

  def new_facility(attributes = nil)
    @facility_group.facilities.new(attributes).tap do |facility|
      facility.district ||= @facility_group.name
      facility.state ||= @facility_group.region.state_region.name
      facility.country ||= Region.root.name
    end
  end

  def set_facility
    @facility = authorize { current_admin.accessible_facilities(:manage).friendly.find(params[:id]) }
  end

  def set_facility_group
    @facility_group = current_admin.accessible_facility_groups(:manage).friendly.find(params[:facility_group_id])
  end

  def set_available_zones
    @available_zones = @facility_group.region.block_regions.pluck(:name).sort
  end

  def facility_params
    params.require(:facility).permit(
      :name,
      :short_name,
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
    ).tap do |transformed_params|
      transformed_params[:teleconsultation_medical_officer_ids] = valid_teleconsultation_medical_officer_ids
    end
  end

  def valid_teleconsultation_medical_officer_ids
    ids = params[:facility][:teleconsultation_medical_officer_ids]
    facilities = current_admin.accessible_facilities(:manage).where(facility_group: @facility_group)

    users = current_admin.accessible_users(:manage)
      .joins(phone_number_authentications: :facility)
      .where(id: ids, phone_number_authentications: {registration_facility_id: facilities})

    users.pluck(:id)
  end

  def initialize_upload
    @errors = []
    @file = params.require(:upload_facilities_file)
  end

  def parse_file
    @file_contents = read_xlsx_or_csv_file(@file)
    facilities = Facility.parse_facilities_from_file(@file_contents)
    @errors = Csv::FacilitiesValidator.validate(facilities).errors
    @facilities = facilities.map { |facility| facility.attributes.with_indifferent_access }
  end

  def file_exists?
    params[:upload_facilities_file].present?
  end
end
