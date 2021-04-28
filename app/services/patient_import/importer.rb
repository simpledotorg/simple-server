class PatientImport::Importer
  include Api::V3::SyncEncounterObservation
  include Api::V3::RetroactiveDataEntry

  attr_reader :params, :facility, :admin, :results

  def self.call(*args)
    new(*args).call
  end

  def initialize(params:, facility:, admin:)
    @params = params
    @facility = facility
    @admin = admin
    @results = []
  end

  def call
    ActiveRecord::Base.transaction do
      params.each_with_index do |patient_record_params, index|
        patient_params = Api::V3::PatientTransformer.from_nested_request(patient_record_params[:patient])
        medical_history_params = Api::V3::MedicalHistoryTransformer.from_request(patient_record_params[:medical_history])
        blood_pressures_params = patient_record_params[:blood_pressures].map { |bp| Api::V3::BloodPressureTransformer.from_request(bp) }
        prescription_drugs_params = patient_record_params[:prescription_drugs].map { |drug| Api::V3::PrescriptionDrugTransformer.from_request(drug) }

        import_patient(patient_params)
        import_blood_pressures(blood_pressures_params)
        import_medical_history(medical_history_params)
        import_prescription_drugs(prescription_drugs_params)

        results.push(
          patient: patient_params,
          medical_history: medical_history_params,
          blood_pressures: blood_pressures_params,
          prescription_drugs: prescription_drugs_params,
        )
      end
    end

    results
  end

  def import_patient(params)
    patient = MergePatientService.new(params, request_metadata: {
      request_facility_id: facility.id,
      request_user_id: PatientImport::ImportUser.find_or_create.id
    }).merge

    PatientImportLog.create!(user: admin, record: patient)
  end

  def import_blood_pressures(params)
    params.each do |bp_params|
      blood_pressure = merge_encounter_observation(:blood_pressures, bp_params)
      PatientImportLog.create!(user: admin, record: blood_pressure)
    }
  end

  def import_medical_history(params)
    medical_history = MedicalHistory.merge(medical_history_params)
    PatientImportLog.create!(user: admin, record: medical_history)
  end

  def import_prescription_drugs(params)
    params.each do |pd_params|
      prescription_drug = PrescriptionDrug.merge(pd_params)
      PatientImportLog.create!(user: admin, record: prescription_drug)
    }
  end

  # SyncEncounterObservation compability
  def current_timezone_offset
    0
  end

  # SyncEncounterObservation compability
  def current_user
    PatientImport::ImportUser.find_or_create
  end
end
