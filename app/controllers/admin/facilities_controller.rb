class Admin::FacilitiesController < AdminController
  include FileUploadable
  before_action :set_facility, only: [:show, :edit, :update, :destroy]
  before_action :set_facility_group, only: [:show, :new, :create, :edit, :update, :destroy]
  before_action :initialize_upload, :validate_file_type, :validate_file_size, :parse_file,
                :validate_at_least_one_facility, :validate_duplicate_rows, :validate_facilities,
                :if => :file_exists?, only: [:upload]

  def index
    authorize Facility
    @organizations = policy_scope(Organization)
  end

  def show
  end

  def new
    @facility = @facility_group.facilities.new
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
    return render :upload, :status => :bad_request if @errors.present?

    if @facilities.present?
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

  def parse_file
    return render :upload, :status => :bad_request if @errors.present?

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
    @row_errors = []
    row_num = 2
    @facilities.each do |facility|
      import_facility = Facility.new(facility)
      @row_errors << [row_num, import_facility.errors.full_messages.to_sentence] if
          import_facility.invalid?
      row_num += 1
    end
    if @row_errors.present?
      group_row_errors.each { |error| @errors << error }
    end
  end

  def file_exists?
    params[:upload_facilities_file].present?
  end

  def file_valid?
    params[:upload_facilities_file].present? && @errors.blank?
  end

  def group_row_errors
    grouped_errors = []
    unique_errors = @row_errors.map { |row, message | message }.uniq
    unique_errors.each do |error|
      rows = @row_errors.select { |row, message| row if error == message }.map { |row, message| row }
      grouped_errors << "Row(s) #{rows.join(', ')}: #{error}"
    end
    grouped_errors
  end

end
