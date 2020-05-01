require 'rails_helper'

RSpec.describe PatientSummaryQuery do
  let(:facility) do
    create(:facility)
  end

  let(:really_overdue_appointments) do
    appointments = create_list(:appointment, 2, facility: facility, scheduled_date: 380.days.ago, status: 'scheduled')
  end

  it "returns nothing for no data" do
    expect(PatientSummaryQuery.call).to eq([])
  end

  it "can filter out appointments overdue more than a year" do
    expected_patients = create_list(:patient, 2, :with_overdue_appointments)
    really_overdue_patients = really_overdue_appointments.map(&:patient)

    result = PatientSummaryQuery.call(filters: ["only_less_than_year_overdue"])

    patients = result.map(&:patient)
    expect(result.map(&:id)).to match_array(patients.map(&:id))
    expect(patients).to match_array(patients)
    expect(patients).to_not match_array(really_overdue_appointments.map(&:patient))
  end

  it "can include appointments overdue more than a year when filter includes them" do
    overdue_patients = create_list(:patient, 2, :with_overdue_appointments)
    expected_patients = overdue_patients + really_overdue_appointments.map(&:patient)

    result = PatientSummaryQuery.call

    patients = result.map(&:patient)
    expect(result.map(&:id)).to match_array(patients.map(&:id))
    expect(patients).to match_array(expected_patients)
  end

  it "can filter to only include patients with phone number" do
    expected_patients = create_list(:patient, 2, :with_overdue_appointments)
    patients_without_phone_numbers = create_list(:patient, 2, :with_overdue_appointments, phone_numbers: [])

    result = PatientSummaryQuery.call(filters: ["phone_number"])
    patients = result.map(&:patient)

    expect(result.map(&:id)).to match_array(expected_patients.map(&:id))
    expect(patients).to match_array(expected_patients)
    expect(patients).to_not match_array(patients_without_phone_numbers)
  end
end