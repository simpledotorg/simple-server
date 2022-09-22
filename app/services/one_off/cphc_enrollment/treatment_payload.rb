class OneOff::CPHCEnrollment::TreatmentPayload
  attr_reader :blood_pressure, :encounter_id, :patient, :prescription_drugs, :appointment

  def initialize(blood_pressure, prescription_drugs, appointment, encounter_id)
    @blood_pressure = blood_pressure
    @encounter_id = encounter_id
    @patient = @blood_pressure.patient
    @prescription_drugs = prescription_drugs
    @appointment = appointment
  end

  def as_json
    medical_history = patient.medical_history

    treatment_date = blood_pressure.recorded_at.strftime("%d-%m-%Y")

    payload = {
      encounterId: encounter_id,
      treat: {
        facility: "DH",
        treatDate: treatment_date,
        reviewDate: treatment_date,
        sys: blood_pressure.systolic,
        diast: blood_pressure.diastolic,
        isTreatmentOnProtocol: false,
        conDn: true,
        removeCurrMedication: true,
        treatDateWithTimeStamp: blood_pressure.recorded_at.to_i,
        dgns: {
          assessDate: blood_pressure.recorded_at.strftime("%d-%m-%Y"),
          diagRresult: medical_history.hypertension ? "CONFIRMED_STAGE_1" : "NAD"
        }
      }
    }

    if appointment.present?
      payload[:treat][:docfolUp] = {
        followUpDueDate: appointment.scheduled_date.strftime("%d-%m-%Y"),
        followUpDuration: "#{appointment.follow_up_days};0;0",
        followUpReason: "Clinical Examination"
      }
    end

    if prescription_drugs.present?
      payload[:treat][:selMeds] = prescription_drugs.map do |prescription_drug|
        {
          dose: nil,
          freq: "Once a day",
          name: prescription_drug.name,
          quan: appointment.present? ? appointment.follow_up_days : 30,
          dur: appointment.present? ? appointment.follow_up_days : 30
        }
      end
    end

    payload
  end
end
