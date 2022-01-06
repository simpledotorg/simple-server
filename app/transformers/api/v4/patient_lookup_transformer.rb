# frozen_string_literal: true

class Api::V4::PatientLookupTransformer < Api::V4::Transformer
  class << self
    def to_response(patient, retention)
      Api::V3::PatientTransformer.to_nested_response(patient).merge(
        {
          medical_history: patient.medical_history.present? ? Api::V3::MedicalHistoryTransformer.to_response(patient.medical_history) : nil,
          appointments: patient.appointments.map { |appointment| Api::V3::AppointmentTransformer.to_response(appointment) },
          blood_pressures: patient.blood_pressures.map { |blood_pressure| Api::V3::BloodPressureTransformer.to_response(blood_pressure) },
          blood_sugars: patient.blood_sugars.map { |blood_sugar| Api::V4::BloodSugarTransformer.to_response(blood_sugar) },
          prescription_drugs: patient.prescription_drugs.map { |prescription_drug| Api::V3::PrescriptionDrugTransformer.to_response(prescription_drug) },
          retention: retention
        }
      )
    end
  end
end
