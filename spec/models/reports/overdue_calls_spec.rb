require "rails_helper"

describe Reports::OverdueCalls, {type: :model, reporting_spec: true} do
  it "includes result of a diagnosed patient" do
    facility = create(:facility)
    patient = create(:patient, diagnosed_confirmed_at: Date.new(2024, 6, 1))
    user_1 = create(:user, registration_facility: facility)
    appointment_1 = create(:appointment, patient: patient,facility: facility, device_created_at: Date.new(2024, 6, 1), user: user_1)
    create(:call_result, appointment: appointment_1, device_created_at: Date.new(2024, 6, 1), user: user_1)
    RefreshReportingViews.refresh_v2
    expect(described_class.where(patient_id: patient.id, month_date: Date.new(2024, 6, 1)).count).to eq(1)
  end

  it "doesn't include results of screened patients" do
    facility = create(:facility)
    patient = create(:patient, :without_medical_history, diagnosed_confirmed_at: nil)
    user_1 = create(:user, registration_facility: facility)
    appointment_1 = create(:appointment, patient: patient,facility: facility, device_created_at: Date.new(2024, 6, 1), user: user_1)
    create(:call_result, appointment: appointment_1, device_created_at: Date.new(2024, 6, 1), user: user_1)
    RefreshReportingViews.refresh_v2
    expect(described_class.where(patient_id: patient.id).count).to eq(0)
  end
end
