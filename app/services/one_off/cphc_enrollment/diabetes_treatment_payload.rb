class OneOff::CphcEnrollment::DiabetesTreatmentPayload
  attr_reader :blood_sugar, :patient, :prescription_drugs, :appointment, :encounter_id

  def initialize(blood_sugar, prescription_drugs, appointment, encounter_id)
    @blood_sugar = blood_sugar
    @patient = blood_sugar.patient
    @prescription_drugs = prescription_drugs
    @appointment = appointment
    @encounter_id = encounter_id
  end

  def payload
    medical_history = patient.medical_history
    treatment_date = blood_sugar.recorded_at.strftime("%Y-%m-%d")
    blood_sugar_payload = OneOff::CphcEnrollment::BloodSugarPayload.new(blood_sugar).payload

    payload = {
      encounterId: encounter_id,
      treat: {
        reviewIn: {
          isProtocolOverriden: false,
          facility: "DH",
          treatDate: treatment_date,
          reviewDate: treatment_date,
          conDn: true,
          remarks: null,
          removeCurrMedication: true,
          treatDateWithTimeStamp: blood_sugar.recorded_at.to_i,
          diabetesDiagnosisModel: {
            date: treatment_date,
            selectedDiagnosis: medical_history.diabetes ? "CONFIRMED" : "NAD"
          }
        }
      }
    }

    payload[:treat][:reviewIn].merge!(blood_sugar_payload.blood_sugar_type_payload)

    if appointment.present?
      payload[:treat][:docfolUp] = {
        followUpDueDate: appointment.scheduled_date.strftime("%d-%m-%Y"),
        followUpDuration: "#{appointment.follow_up_days};0;0",
        followUpReason: "Clinical Examination"
      }
    end

    if prescription_drugs.present?
      payload[:treat][:reviewIn][:selMeds] = prescription_drugs.map do |prescription_drug|
        {
          dose: nil,
          freq: "Once a day",
          name: prescription_drug.name,
          quan: appointment.present? ? appointment.follow_up_days : 30,
          dur: appointment.present? ? appointment.follow_up_days : 30
        }
      end
    end
  end
end
