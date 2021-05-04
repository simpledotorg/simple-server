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
        results.push(import_patient_record(patient_record_params))
      end
    end

    results
  end

  def import_patient_record(params)
    ActiveRecord::Base.transaction do
      patient_params = Api::V3::PatientTransformer.from_nested_request(params[:patient])
      medical_history_params = Api::V3::MedicalHistoryTransformer.from_request(params[:medical_history])
      blood_pressures_params = params[:blood_pressures].map { |bp| Api::V3::BloodPressureTransformer.from_request(bp) }
      prescription_drugs_params = params[:prescription_drugs].map { |drug| Api::V3::PrescriptionDrugTransformer.from_request(drug) }

      patient = import_patient(patient_params)
      medical_history = import_medical_history(medical_history_params)
      blood_pressures = import_blood_pressures(blood_pressures_params)
      prescription_drugs = import_prescription_drugs(prescription_drugs_params)

      records = [
        patient,
        medical_history,
        *blood_pressures,
        *prescription_drugs
      ]

      if records.all?(&:persisted?)
        AuditLog.create_logs_async(records, "import", Time.current)
      else
        raise "Patient import failed"
      end
    end

    params
  end

  def import_patient(params)
    MergePatientService.new(params, request_metadata: {
      request_facility_id: facility.id,
      request_user_id: PatientImport::ImportUser.find_or_create.id
    }).merge
  end

  def import_blood_pressures(params)
    params.map do |bp_params|
      merge_encounter_observation(:blood_pressures, bp_params)
    end
  end

  def import_medical_history(params)
    MedicalHistory.merge(params)
  end

  def import_prescription_drugs(params)
    params.map do |pd_params|
      PrescriptionDrug.merge(pd_params)
    end
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
