require 'tempfile'

class Admin::FacilitiesController < AdminController
  before_action :set_facility, only: [:show, :edit, :update, :destroy]
  before_action :set_facility_group, only: [:show, :new, :create, :edit, :update, :destroy]

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
    file = params[:upload_facilities_file]
    @file_contents = ''
    @errors = []
    run_validations_and_read(file) if file.present?
    if @errors.present?
      @errors.prepend "Please fix the errors below and try again:"
      flash.now[:alert] = @errors.join('<br/>').html_safe
    elsif file.present?
      facilities = Facility.parse_facilities(@file_contents)
      ImportFacilitiesJob.perform_later(facilities)
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

  # Validation functions
  def run_validations_and_read(file)
    validate_facilities_file(file)
    return nil if @errors.present?

    # This assignment is to avoid creating a temp file and passing it around
    @file_contents = Facility.read_import_file(file)
    validate_facilities_fields(@file_contents)
  end

  def validate_facilities_file(file)
    # File level validations
    @errors << 'File type not supported, please upload a csv or xlsx file instead' if
        valid_mime_types.exclude? file.content_type
    @errors << 'File is too big, must be smaller than 5MB' if file.size > 5.megabytes
  end

  def validate_facilities_fields(file_contents)
    # Row validations
    facilities = Facility.parse_facilities(file_contents)
    # Check that the file has at least one facility
    validate_at_least_one_facility(facilities)

    # Look for duplicates in the import file
    validate_duplicate_rows(facilities)

    # Do Facility model validations
    row_num = 2
    facilities.each do |facility|
      import_facility = Facility.new(facility)
      if import_facility.invalid?
        row_errors = import_facility.errors.full_messages.to_sentence
        @errors << "Row #{row_num}: #{row_errors}" if row_errors.present?
      end
      row_num += 1
    end
  end

  def validate_at_least_one_facility(facilities)
    @errors << "Uploaded file doesn't contain any valid facilities" if facilities.blank?
  end

  def validate_duplicate_rows(facilities)
    # Ensure no duplicate rows are present in the uploaded file
    facilities_slice = facilities.map { |facility|
      facility.slice(:organization_name, :facility_group_name, :name) }
    @errors << 'Uploaded file has duplicate facilities' if
        facilities_slice.count != facilities_slice.uniq.count
  end

  def valid_mime_types
    %w[
      text/csv
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    ].freeze
  end
end
