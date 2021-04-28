class Admin::PatientImportsController < AdminController
  include FileUploadable

  def new
    authorize { current_admin.power_user? }
  end

  def create
    authorize { current_admin.power_user? }

    facility = Facility.find(params[:facility_id])

    data = read_xlsx_or_csv_file(params[:patient_import_file])
    params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)
    errors = PatientImport::Validator.new(params).errors

    if errors.values.flatten.any?
      @errors = errors
      render :new
    else
      results = PatientImport::Importer.call(params: params, facility: facility)
      redirect_to new_admin_patient_import_url, notice: "Successfully imported #{results.count} patients to #{facility.name}"
    end
  end
end
