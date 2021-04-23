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
    errors = {}

    # Validation
    params.each_with_index do |patient_params, index|
      patient_validator = Api::V3::PatientPayloadValidator.new(**patient_params[:patient], skip_facility_authorization: true).tap(&:valid?)
      medical_history_validator = Api::V3::MedicalHistoryPayloadValidator.new(patient_params[:medical_history]).tap(&:valid?)
      blood_pressure_validators = patient_params[:blood_pressures].map { |bp| Api::V3::BloodPressurePayloadValidator.new(bp).tap(&:valid?) }
      prescription_drug_validators = patient_params[:prescription_drugs].map { |drug| Api::V3::PrescriptionDrugPayloadValidator.new(drug).tap(&:valid?) }

      errors[index] = [
        patient_validator.errors.full_messages,
        medical_history_validator.errors.full_messages,
        blood_pressure_validators.flat_map { |validator| validator.errors.full_messages },
        prescription_drug_validators.flat_map { |validator| validator.errors.full_messages }
      ]
    end

    other_params = []
    # Load
    params.each_with_index do |patient_record_params, index|
      patient_params = Api::V3::PatientTransformer.from_nested_request(patient_record_params[:patient])
      medical_history_params = Api::V3::MedicalHistoryTransformer.from_request(patient_record_params[:medical_history])
      blood_pressures_params = patient_record_params[:blood_pressures].map { |bp| Api::V3::BloodPressureTransformer.from_request(bp) }
      prescription_drugs_params = patient_record_params[:prescription_drugs].map { |drug| Api::V3::PrescriptionDrugTransformer.from_request(drug) }


      other_params.push(
        patient: patient_params,
        medical_history: medical_history_params,
        blood_pressures: blood_pressures_params,
        prescription_drugs: prescription_drugs_params,
      )
    end

    render json: other_params
  end
end
