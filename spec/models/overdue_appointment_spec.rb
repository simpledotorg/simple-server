require 'rails_helper'

describe OverdueAppointment do
  describe 'OverdueAppointment' do
    it 'builds for patient with an overdue scheduled appointment' do
      patient = FactoryBot.create(:patient)
      blood_pressure = FactoryBot.create(:blood_pressure, patient: patient)
      appointment_in_past = FactoryBot.create(:appointment,
                                              patient: patient,
                                              status: :scheduled,
                                              scheduled_date: Date.today - 5.days)
      overdue_appointment = OverdueAppointment.for_patient(patient)

      expect(overdue_appointment.patient).to eq(patient)
      expect(overdue_appointment.blood_pressure).to eq(blood_pressure)
      expect(overdue_appointment.appointment).to eq(appointment_in_past)
    end

    it 'does not build for patient without an overdue scheduled appointment' do
      patient = FactoryBot.create(:patient)
      FactoryBot.create(:blood_pressure, patient: patient)
      FactoryBot.create(:appointment,
                        patient: patient,
                        status: :scheduled,
                        scheduled_date: Date.today + 5.days)
      overdue_appointment = OverdueAppointment.for_patient(patient)

      expect(overdue_appointment).to be_nil
    end
  end
end
