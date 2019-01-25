require 'rails_helper'

describe OverdueAppointment do
  let(:date_in_past) { Date.today - 5.days }
  let(:date_in_future) { Date.today + 5.days }

  describe 'OverdueAppointment' do
    it 'builds for patient with an overdue scheduled appointment' do
      patient = create(:patient)
      blood_pressure = create(:blood_pressure, patient: patient)
      appointment_in_past = create(:appointment,
                                   patient: patient,
                                   status: :scheduled,
                                   scheduled_date: date_in_past)
      overdue_appointment = OverdueAppointment.for_patient(patient)

      expect(overdue_appointment.patient).to eq(patient)
      expect(overdue_appointment.blood_pressure).to eq(blood_pressure)
      expect(overdue_appointment.appointment).to eq(appointment_in_past)
    end

    it 'does not build for patient without an overdue scheduled appointment' do
      patient = create(:patient)
      create(:blood_pressure, patient: patient)
      create(:appointment,
             patient: patient,
             status: :scheduled,
             scheduled_date: date_in_future)
      overdue_appointment = OverdueAppointment.for_patient(patient)

      expect(overdue_appointment).to be_nil
    end

    it 'builds for patients registered in authorized facilities' do
      healthcare_counsellor = create(:admin, :healthcare_counsellor)
      facility = create(:facility, facility_group: healthcare_counsellor.facility_groups.first)
      patient = create(:patient, registration_facility: facility)
      create(:blood_pressure, patient: patient)
      create(:appointment,
             patient: patient,
             status: :scheduled,
             scheduled_date: date_in_past)
      overdue_appointments = OverdueAppointment.for_admin(healthcare_counsellor)

      expect(overdue_appointments).to contain_exactly(OverdueAppointment.for_patient(patient))
    end
  end
end
