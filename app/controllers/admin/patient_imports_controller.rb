# frozen_string_literal: true

class Admin::PatientImportsController < AdminController
  include FileUploadable

  def new
    authorize { current_admin.power_user? }
  end

  def create
    authorize { current_admin.power_user? }

    facility = Facility.find(params[:facility_id])
    data = read_xlsx_or_csv_file(params[:patient_import_file])

    missing_fields = required_import_fields - import_headers(data)
    if missing_fields.any?
      missing_field_errors = missing_fields.map { |missing_header|
        "#{missing_header} is missing from the import file. Please ensure you're using the correct patient import template."
      }

      @errors = {"Headers" => missing_field_errors}
      render(:new) && return
    end

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

  private

  def import_headers(data)
    rows = CSV.parse(data, headers: true)
    rows.first.to_h.keys
  end

  def required_import_fields
    %w[
      registration_date
      full_name
      age
      gender
      village
      medical_history_hypertension
      medical_history_diabetes
      medical_history_heart_attack
      medical_history_stroke
      medical_history_kidney_disease
    ]
  end
end
