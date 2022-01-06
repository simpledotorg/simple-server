# frozen_string_literal: true

class PatientImport::Validator
  attr_reader :params, :errors

  def initialize(params)
    @params = params
    @errors = {}
  end

  def validate
    params.each_with_index do |patient_params, index|
      patient_validator = Api::V3::PatientPayloadValidator.new(patient_params[:patient].merge(skip_facility_authorization: true)).tap(&:valid?)
      medical_history_validator = Api::V3::MedicalHistoryPayloadValidator.new(patient_params[:medical_history]).tap(&:valid?)
      blood_pressure_validators = patient_params[:blood_pressures].map { |bp| Api::V3::BloodPressurePayloadValidator.new(bp).tap(&:valid?) }
      prescription_drug_validators = patient_params[:prescription_drugs].map { |drug| Api::V3::PrescriptionDrugPayloadValidator.new(drug).tap(&:valid?) }

      errors[index] = [
        *patient_validator.errors.full_messages,
        *medical_history_validator.errors.full_messages,
        *(blood_pressure_validators.flat_map { |validator| validator.errors.full_messages }),
        *(prescription_drug_validators.flat_map { |validator| validator.errors.full_messages })
      ]
    end
  end

  def valid?
    validate

    !errors.values.flatten.any?
  end
end
