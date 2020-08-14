require "rails_helper"

RSpec.describe NoBPMeasureService do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :supervisor, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
    end
  end

  it "counts visits in past three months for appts, drugs updated, blood sugar taken without blood pressures" do
    jan_1 = Time.parse("January 1st, 2020")
    may_1 = Time.parse("May 1st, 2020")
    may_15 = Time.parse("May 15th, 2020")
    facility = create(:facility, facility_group: facility_group_1)
    facility_2 = create(:facility)

    Timecop.freeze(jan_1) do # freeze time so all patients are registered before visit range
      # visit: patient has appointment but no BP
      patient_visited_via_appt = create(:patient, registration_facility: facility)
      create(:appointment, creation_facility: facility, scheduled_date: may_1, device_created_at: may_1, patient: patient_visited_via_appt)

      # visit: patient has new drugs prescribed but no BP
      patient_visited_via_drugs = create(:patient, full_name: "visit via drugs", registration_facility: facility)
      patient_visited_via_drugs.prescription_drugs << build(:prescription_drug, device_created_at: may_15)

      # visit: patient has blood sugar but no BP
      patient_visited_via_blood_sugar = create(:patient, full_name: "visit via blood sugar", registration_facility: facility)
      patient_visited_via_blood_sugar.blood_sugars << build(:blood_sugar, device_created_at: may_15)

      # no visit: patient has only a BP
      _patient_without_visit_and_bp = create(:patient, full_name: "no visits and no BP", registration_facility: facility)

      # no visit: patient has an appointment and a BP
      patient_with_bp = create(:patient, registration_facility: facility)
      create(:appointment, creation_facility: facility, scheduled_date: may_15, device_created_at: may_15, patient: patient_with_bp)
      create(:blood_pressure, :under_control, facility: facility, patient: patient_with_bp, recorded_at: may_15)

      # no visit: patient from a different facility has an appointment
      patient_from_different_facility = create(:patient, registration_facility: facility_2)
      create(:appointment, creation_facility: facility_2, scheduled_date: may_15, device_created_at: may_15, patient: patient_from_different_facility)
    end

    range = (Period.month("October 1 2018")..Period.month("October 1 2020"))
    results = NoBPMeasureService.new(facility, periods: range).call

    months_with_visits = ["May 2020", "June 2020", "July 2020"].map { |str| Period.month(str) }
    entries_with_visits, entries_without_visits = results.partition { |key, period| key.in?(months_with_visits) }

    entries_with_visits.each do |(period, count)|
      expect(count).to eq(3)
    end

    entries_without_visits.each do |(period, count)|
      expect(count).to eq(0)
    end
  end
end
