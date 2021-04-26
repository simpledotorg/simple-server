class PatientImport::Importer
  include Api::V3::SyncEncounterObservation
  include Api::V3::RetroactiveDataEntry

  attr_reader :params, :facility, :results

  def self.call(*args)
    new(*args).call
  end

  def initialize(params:, facility:)
    @params = params
    @facility = facility
    @results = []
  end

  def call
    ActiveRecord::Base.transaction do
      params.each_with_index do |patient_record_params, index|
        patient_params = Api::V3::PatientTransformer.from_nested_request(patient_record_params[:patient])
        medical_history_params = Api::V3::MedicalHistoryTransformer.from_request(patient_record_params[:medical_history])
        blood_pressures_params = patient_record_params[:blood_pressures].map { |bp| Api::V3::BloodPressureTransformer.from_request(bp) }
        prescription_drugs_params = patient_record_params[:prescription_drugs].map { |drug| Api::V3::PrescriptionDrugTransformer.from_request(drug) }

        MergePatientService.new(patient_params, request_metadata: {
          request_facility_id: facility.id,
          request_user_id: PatientImport::ImportUser.find_or_create.id
        }).merge

        blood_pressures_params.each {|bp_params| merge_encounter_observation(:blood_pressures, bp_params)}

        MedicalHistory.merge(medical_history_params)

        prescription_drugs_params.each {|pd_params| PrescriptionDrug.merge(pd_params) }


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

  # SyncEncounterObservation compability
  def current_timezone_offset
    0
  end

  # SyncEncounterObservation compability
  def current_user
    PatientImport::ImportUser.find_or_create
  end
end
