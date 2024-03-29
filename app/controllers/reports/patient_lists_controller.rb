class Reports::PatientListsController < AdminController
  include ZipKit::RailsStreaming
  attr_reader :scope, :region, :download_params

  before_action :set_scope, only: [:show, :diabetes]
  before_action :set_region, only: [:show, :diabetes]
  before_action :set_download_params, only: [:show, :diabetes]

  def show
    case region_class
    when "facility"
      model = Facility.find(download_params[:facility_id])
      model_name = model.name
    when "facility_group"
      model = FacilityGroup.find(download_params[:id])
      model_name = model.name
    else
      raise ArgumentError, "unknown model_type #{region_class.inspect}"
    end

    patients = model.assigned_patients.excluding_dead
    exporter = PatientsWithHistoryExporter
    file_name = "patient-list_#{@region.region_type}_#{@region.name}_#{I18n.l(Date.current)}"
    response.headers["Last-Modified"] = Time.zone.now.ctime.to_s

    return zip_kit_stream(filename: "#{file_name}.zip") do |zip|
      zip.write_deflated_file("#{file_name}.csv") do |sink|
        CSV(sink) do |csv_write|
          exporter.csv_enumerator(patients, display_blood_sugars: model.region.diabetes_management_enabled?).each do |row|
            csv_write << row
          end
        end
      end
    end
  end

  private

  def recipient_email
    current_admin.email
  end

  def set_scope
    @scope = if region_class == "facility_group"
      authorize { current_admin.accessible_district_regions(:view_pii) }
    else
      authorize { current_admin.accessible_facility_regions(:view_pii) }
    end
  end

  def set_region
    @region = scope.find_by!(slug: params[:id])
  end

  def set_download_params
    @download_params = if region_class == "facility_group"
      {id: region.source_id}
    else
      {facility_id: region.source_id}
    end
  end

  def filtered_params
    params.permit(:id, :report_scope)
  end

  def region_class
    @region_class ||=
      case filtered_params[:report_scope]
      when "district"
        "facility_group"
      when "facility"
        "facility"
      else
        raise ActiveRecord::RecordNotFound, "unknown report scope #{filtered_params[:report_scope].inspect}"
      end
  end
end
