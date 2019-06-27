class Admin::FacilitiesController < AdminController
  include FileUploadable
  before_action :set_facility, only: [:show, :edit, :update, :destroy]
  before_action :set_facility_group, only: [:show, :new, :create, :edit, :update, :destroy]
  before_action :initialize_upload, :validate_file_type, :validate_file_size, :if => :file_exists?, only: [:upload]
  before_action :parse_file, :validate_at_least_one_facility, :validate_duplicate_rows, :validate_facilities,
                :if => :file_valid?, only: [:upload]


  VALID_MIME_TYPES = %w[text/csv application/vnd.openxmlformats-officedocument.spreadsheetml.sheet].freeze

  def index
    authorize Facility
    @organizations = policy_scope(Organization)
  end

  def show
  end

  def new
    @facility = Facility.new
    authorize @facility
  end

  def edit
  end

  def create
    @facility = @facility_group.facilities.new(facility_params)
    authorize @facility

    if @facility.save
      redirect_to [:admin, @facility_group, @facility], notice: 'Facility was successfully created.'
    else
      render :new
    end
  end

  def update
    if @facility.update(facility_params)
      redirect_to [:admin, @facility_group, @facility], notice: 'Facility was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @facility.destroy
    redirect_to admin_facilities_url, notice: 'Facility was successfully deleted.'
  end

  def upload
    authorize Facility
    if @errors.present?
      render :upload, :status => :bad_request
      return
    elsif @facilities.present?
      ImportFacilitiesJob.perform_later(@facilities)
      flash.now[:notice] = 'File upload successful, your facilities will be created shortly.'
    end
    render :upload
  end

  private

  def set_facility
    @facility = Facility.friendly.find(params[:id])
    authorize @facility
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
      :latitude,
      :longitude
    )
  end

  def initialize_upload
    @errors = []
    @file = params.require(:upload_facilities_file)
  end

  def validate_file_type
    @errors << 'File type not supported, please upload a csv or xlsx file instead' if
        VALID_MIME_TYPES.exclude?(@file.content_type)
  end

  def validate_file_size
    @errors << 'File is too big, must be smaller than 5MB' if @file.size > 5.megabytes
  end

  def parse_file
    render :upload, :status => :bad_request if @errors.present?

    @file_contents = read_xlsx_or_csv_file(@file)
    @facilities = Facility.parse_facilities(@file_contents)
  end

  def validate_at_least_one_facility
    @errors << "Uploaded file doesn't contain any valid facilities" if @facilities.blank?
  end

  def validate_duplicate_rows
    facilities_slice = @facilities.map { |facility|
      facility.slice(:organization_name, :facility_group_name, :name) }
    @errors << 'Uploaded file has duplicate facilities' if
        facilities_slice.count != facilities_slice.uniq.count
  end

  def validate_facilities
    row_num = 2
    @facilities.each do |facility|
      import_facility = Facility.new(facility)
      if import_facility.invalid?
        row_errors = import_facility.errors.full_messages.to_sentence
        @errors << "Row #{row_num}: #{row_errors}" if row_errors.present?
      end
      row_num += 1
    end
  end

  def file_exists?
    params[:upload_facilities_file].present?
  end

  def file_valid?
    params[:upload_facilities_file].present? && @errors.blank?
  end
end
