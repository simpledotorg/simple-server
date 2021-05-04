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
    validator = PatientImport::Validator.new(params)

    if validator.valid?
      results = PatientImport::Importer.import_patients(patients_params: params, facility: facility, admin: current_admin)
      redirect_to new_admin_patient_import_url, notice: "Successfully imported #{results.count} patients to #{facility.name}"
    else
      @errors = validator.errors
      render :new
    end
  end
end
