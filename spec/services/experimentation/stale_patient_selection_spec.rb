require "rails_helper"

RSpec.describe Experimentation::StalePatientSelection, type: :model do
  it "only selects from patients 18 and older" do
    young_patient = create(:patient, age: 17)
    create(:blood_pressure, patient: young_patient, device_created_at: 100.days.ago)
    old_patient = create(:patient, age: 18)
    create(:blood_pressure, patient: old_patient, device_created_at: 100.days.ago)

    result = described_class.call(date: Date.tomorrow)

    expect(result).to contain_exactly(old_patient.id)
  end

  it "only selects hypertensive patients" do
    hypertensive = create(:patient, age: 80)
    create(:blood_pressure, patient: hypertensive, device_created_at: 100.days.ago)
    non_hypertensive = create(:patient, :without_hypertension, age: 80)
    create(:blood_pressure, patient: non_hypertensive, device_created_at: 100.days.ago)

    result = described_class.call(date: Date.tomorrow)

    expect(result).to contain_exactly(hypertensive.id)
  end

  it "only selects patients with mobile phones" do
    patient_without_phone = create(:patient, age: 80, phone_numbers: [])
    patient_with_landline = create(:patient, phone_numbers: [build(:patient_phone_number, phone_type: :landline)])
    create(:blood_pressure, patient: patient_without_phone, device_created_at: 100.days.ago)
    create(:blood_pressure, patient: patient_with_landline, device_created_at: 100.days.ago)

    patient_with_phone = create(:patient, age: 80)
    create(:blood_pressure, patient: patient_with_phone, device_created_at: 100.days.ago)

    result = described_class.call(date: Date.tomorrow)

    expect(result).to contain_exactly(patient_with_phone.id)
  end

  it "only selects patients whose last visit was in the selected date range" do
    eligible_1 = create(:patient, age: 55)
    create(:prescription_drug, patient: eligible_1, device_created_at: 70.days.ago)
    eligible_2 = create(:patient, age: 80)
    create(:appointment, patient: eligible_2, device_created_at: 100.days.ago, scheduled_date: 80.days.ago)
    ineligible_1 = create(:patient, age: 80)
    create(:blood_sugar, patient: ineligible_1, device_created_at: 370.days.ago)
    ineligible_2 = create(:patient, age: 80)
    create(:blood_pressure, patient: ineligible_2, device_created_at: 1.days.ago)

    result = described_class.call(date: Date.tomorrow)

    expect(result).to contain_exactly(eligible_1.id, eligible_2.id)
  end

  it "only selects patients who have no appointments scheduled in the future" do
    patient_with_future_appt = create(:patient, age: 80)
    create(:blood_pressure, patient: patient_with_future_appt, device_created_at: 40.days.ago)
    patient_with_future_appt.appointments << create(:appointment, scheduled_date: Date.current + 1.day, status: "scheduled")

    patient_with_past_appt = create(:patient, age: 80)
    create(:blood_pressure, patient: patient_with_past_appt, device_created_at: 40.days.ago)
    create(:appointment, patient: patient_with_past_appt, device_created_at: 70.days.ago, scheduled_date: 40.days.ago)

    result = described_class.call(date: Date.tomorrow)

    expect(result).to contain_exactly(patient_with_past_appt.id)
  end

  it "does not include the same patient more than once" do
    patient = create(:patient, age: 80)
    create(:blood_pressure, patient: patient, device_created_at: 40.days.ago)
    create(:blood_pressure, patient: patient, device_created_at: 90.days.ago)
    patient.appointments << create(:appointment, scheduled_date: 90.days.ago, status: "scheduled")

    result = described_class.call(date: Date.tomorrow)

    expect(result).to contain_exactly(patient.id)
  end
end
