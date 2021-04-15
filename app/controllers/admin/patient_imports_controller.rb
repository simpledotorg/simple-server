class Admin::PatientImportsController < AdminController
  include FileUploadable

  def new
    authorize { current_admin.power_user? }
  end

  def create
    authorize { current_admin.power_user? }

    facility = Facility.find(params[:facility_id])

    data = read_xlsx_or_csv_file(params[:patient_import_file])
    params = PatientImport::SpreadsheetTransformer.transform(data, facility: facility)
    render json: params.to_json
  end
end
