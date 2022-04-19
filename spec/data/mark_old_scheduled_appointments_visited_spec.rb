require "rails_helper"
require Rails.root.join("db", "data", "20220419114625_mark_old_scheduled_appointments_visited")

RSpec.describe MarkOldScheduledAppointmentsVisited do
  it "marks older scheduled appointments visited for patients who have multiple scheduled appointments" do
    # patient with no appointments
    patient_1 = create(:patient)
    # patient with one scheduled appointment
    patient_2 = create(:patient)
    # patient with multiple appointments
    patient_3 = create(:patient)

    patient_2_appointment_1 = create(:appointment, status: :scheduled, patient: patient_2)
    patient_3_appointment_1 = create(:appointment, status: :scheduled, patient: patient_3, scheduled_date: 1.year.ago)
    patient_3_appointment_2 = create(:appointment, status: :scheduled, patient: patient_3, scheduled_date: 6.months.ago)
    patient_3_appointment_3 = create(:appointment, status: :scheduled, patient: patient_3, scheduled_date: 1.month.ago)

    described_class.new.up

    expect(patient_1.latest_scheduled_appointments.count).to eq(0)
    expect(patient_2.latest_scheduled_appointments).to match_array([patient_2_appointment_1])
    expect(patient_3.latest_scheduled_appointments).to match_array([patient_3_appointment_3])
    expect(patient_3_appointment_1.reload.status).to eq("visited")
    expect(patient_3_appointment_2.reload.status).to eq("visited")
  end

  it "sets updated_at correctly" do
    Timecop.freeze(Time.current) do
      # patient with multiple appointments
      patient = create(:patient)
      last_month = Time.current - 1.month

      appointment_1 = create(:appointment, status: :scheduled, patient: patient, scheduled_date: 1.year.ago, updated_at: last_month)
      appointment_2 = create(:appointment, status: :scheduled, patient: patient, scheduled_date: 6.months.ago, updated_at: last_month)
      appointment_3 = create(:appointment, status: :scheduled, patient: patient, scheduled_date: 1.month.ago, updated_at: last_month)

      described_class.new.up

      expect(appointment_1.reload.updated_at).to eq(Time.current)
      expect(appointment_2.reload.updated_at).to eq(Time.current)
      expect(appointment_3.reload.updated_at).to eq(last_month)
    end
  end
end
