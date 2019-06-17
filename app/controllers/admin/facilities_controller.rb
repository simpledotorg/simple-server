require 'csv'

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
    @file = params[:upload_facilities_file]
    if @file.present?
      errors = validate_upload_facilities_file
      if errors.present?
        flash[:alert] = errors
      else
        flash[:notice] = "File upload successful, your facilities will be created shortly."
      end
      render :upload
    else
      render :upload
    end
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

  def validate_upload_facilities_file
    errors = []
    errors << "File type not supported, please upload a CSV file instead" if
            ["text/csv"].exclude? @file.content_type

    errors << "File is too big, must be smaller than 5MB" if @file.size > 5.megabytes
    errors << validate_upload_facilities_fields if errors.blank?
    errors.join("<br/>").html_safe
  end

  def validate_upload_facilities_fields
    errors = []
    row_num = 2
    CSV.parse(@file.tempfile, headers: true, converters: :strip_whitespace) do |row|
      facility = Facility.new(organization_name: row['organization'],
                              facility_group_name: row['facility_group'],
                              name: row['facility_name'],
                              facility_type: row['facility_type'],
                              street_address: row['street_address'],
                              village_or_colony: row['village_or_colony'],
                              district: row['district'],
                              state: row['state'],
                              country: row['country'],
                              pin: row['pin'],
                              latitude: row['latitude'],
                              longitude: row['longitude'],
                              import: true)
      if facility.invalid?
        row_errors = facility.errors.full_messages.to_sentence
        errors << "Row #{row_num}: #{row_errors}"
      end
      row_num += 1
    end
    errors
  end

  CSV::Converters[:strip_whitespace] = ->(value) { value.strip rescue value }
end
