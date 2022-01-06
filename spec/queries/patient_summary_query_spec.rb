# frozen_string_literal: true

require "rails_helper"

RSpec.describe PatientSummaryQuery do
  let(:facility) do
    create(:facility)
  end

  let(:really_overdue_appointments) do
    create_list(:appointment, 2,
      facility: facility,
      scheduled_date: 380.days.ago,
      status: "scheduled",
      patient: create(:patient, registration_facility: facility))
  end

  it "returns nothing for no data" do
    expect(PatientSummaryQuery.call(assigned_facilities: [facility])).to eq([])
  end

  context "when only_overdue is false" do
    it "returns all patients with unvisited appointments" do
      patient = create(:patient, registration_facility: facility)
      create(:appointment, status: :cancelled, scheduled_date: 1.month.ago, patient: patient, facility: facility)

      expect(PatientSummaryQuery.call(assigned_facilities: [facility]).map(&:patient)).not_to include(patient)
      expect(PatientSummaryQuery.call(assigned_facilities: [facility], only_overdue: false).map(&:patient)).to include(patient)
    end
  end

  it "ignores phone number filters if both filters are set" do
    create(:patient, :with_overdue_appointments, registration_facility: facility)
    create(:patient, :with_overdue_appointments, registration_facility: facility, phone_numbers: [])

    result = PatientSummaryQuery.call(assigned_facilities: [facility], filters: ["phone_number", "no_phone_number"])
    expected_patients = result.map(&:patient)
    expect(result.map(&:id)).to match_array(expected_patients.map(&:id))
  end

  it "can filter out appointments overdue more than a year" do
    expected_patients = create_list(:patient, 2, :with_overdue_appointments, registration_facility: facility)
    really_overdue_patients = really_overdue_appointments.map(&:patient)

    result = PatientSummaryQuery.call(assigned_facilities: [facility], filters: ["only_less_than_year_overdue"])

    patients = result.map(&:patient)
    expect(result.map(&:id)).to match_array(expected_patients.map(&:id))
    expect(patients).to match_array(expected_patients)
    expect(patients).to_not match_array(really_overdue_patients)
  end

  it "can include appointments overdue more than a year when filter includes them" do
    overdue_patients = create_list(:patient, 2, :with_overdue_appointments, registration_facility: facility)
    expected_patients = overdue_patients + really_overdue_appointments.map(&:patient).uniq

    result = PatientSummaryQuery.call(assigned_facilities: [facility])

    patients = result.map(&:patient)
    expect(result.map(&:id)).to match_array(patients.map(&:id))
    expect(patients).to match_array(expected_patients)
  end

  it "can filter to only include patients with phone number" do
    expected_patients = create_list(:patient, 2, :with_overdue_appointments, registration_facility: facility)
    patients_without_phone_numbers = create_list(:patient, 2, :with_overdue_appointments, registration_facility: facility, phone_numbers: [])

    result = PatientSummaryQuery.call(assigned_facilities: [facility], filters: ["phone_number"])
    patients = result.map(&:patient)

    expect(result.map(&:id)).to match_array(expected_patients.map(&:id))
    expect(patients).to match_array(expected_patients)
    expect(patients).to_not match_array(patients_without_phone_numbers)
  end
end
