class Reports::PatientListsController < AdminController
  include ZipTricks::RailsStreaming

  attr_reader :scope, :region, :download_params

  before_action :set_scope, only: [:show, :diabetes]
  before_action :set_region, only: [:show, :diabetes]
  before_action :set_download_params, only: [:show, :diabetes]

  def show
    if Flipper.enabled?(:patient_list_direct_download)
      Datadog::Tracing.trace("Direct patient line list download") do
        patients = @region.assigned_patients.excluding_dead
        enumerator = PatientsWithHistoryExporter.csv_enumerator(patients)

        file_name = "patient-list_#{@region.region_type}_#{@region.name}_#{I18n.l(Date.current)}"
        csv_file_name = "#{file_name}.csv"
        zip_archive_name = "#{file_name}.zip"
        response.headers["Content-Disposition"] = ActionDispatch::Http::ContentDisposition.format(
          disposition: "attachment",
          filename: zip_archive_name
        )

        first_row = enumerator.peek
        response.headers["Last-Modified"] = first_row.second

        return zip_tricks_stream do |zip|
          zip.write_deflated_file(csv_file_name) do |sink|
            CSV(sink) do |csv_write|
              enumerator.each do |row|
                csv_write << row
              end
            end
          end
        end
      end
    end

    PatientListDownloadJob.perform_async(recipient_email, region_class, download_params)

    redirect_back(
      fallback_location: reports_region_path(region, report_scope: params[:report_scope]),
      notice: I18n.t("patient_list_email.notice",
        model_type: filtered_params[:report_scope],
        model_name: region.name)
    )
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
