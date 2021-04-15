class Admin::PatientImportsController < AdminController
  include FileUploadable

  def new
    authorize { current_admin.power_user? }
  end

  def create
    authorize { current_admin.power_user? }

    data = read_xlsx_or_csv_file(params[:patient_import_file])
    params = PatientImport::SpreadsheetTransformer.transform(data)
    render plain: params
  end
end
