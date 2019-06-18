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
      @errors = []
      validate_facilities_file(@file)
      file_contents = @file.read if @errors.blank?
      validate_facilities_fields(file_contents) if @errors.blank?
      if @errors.present?
        flash.now[:alert] = @errors.join("<br/>").html_safe
      else
        facilities = Facility.parse_csv(file_contents)
        ImportFacilitiesJob.perform_later(facilities)
        flash.now[:notice] = "File upload successful, your facilities will be created shortly."
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

  def validate_facilities_file(file)
    @errors << "File type not supported, please upload a CSV file instead" if
            ["text/csv"].exclude? file.content_type

    @errors << "File is too big, must be smaller than 5MB" if file.size > 5.megabytes
  end

  def validate_facilities_fields(file_contents)
    facilities = Facility.parse_csv(file_contents)
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
end
