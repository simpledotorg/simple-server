require "rails_helper"

RSpec.describe NoBPMeasureService do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :supervisor, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  let(:june_1_2018) { Time.parse("June 1, 2018 00:00:00+00:00") }
  let(:june_1_2020) { Time.parse("June 1, 2020 00:00:00+00:00") }
  let(:june_30_2020) { Time.parse("June 30, 2020 00:00:00+00:00") }
  let(:july_2020) { Time.parse("July 15, 2020 00:00:00+00:00") }
  let(:jan_2019) { Time.parse("January 1st, 2019 00:00:00+00:00") }
  let(:jan_2020) { Time.parse("January 1st, 2020 00:00:00+00:00") }
  let(:july_2018) { Time.parse("July 1st, 2018 00:00:00+00:00") }
  let(:july_2020) { Time.parse("July 1st, 2020 00:00:00+00:00") }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
    end
  end

  it "counts visits in past three months for appts, drugs updated, blood sugar taken without blood pressures" do
    may_1 = Time.parse("May 1st, 2020")
    may_15 = Time.parse("May 15th, 2020")
    facility = create(:facility, facility_group: facility_group_1)
    facility_2 = create(:facility)
    Timecop.freeze(may_1) do # freeze time so all patients are registered at a set time
      patient_visited_via_appt = create(:patient, registration_facility: facility)
      patient_visited_via_drugs = create(:patient, full_name: "visit via drugs", registration_facility: facility)
      patient_visited_via_drugs.prescription_drugs << build(:prescription_drug, device_created_at: may_15)
      patient_visited_via_blood_sugar = create(:patient, full_name: "visit via blood sugar", registration_facility: facility)
      patient_visited_via_blood_sugar.blood_sugars << build(:blood_sugar, device_created_at: may_15)

      patient_without_visit_and_bp = create(:patient, full_name: "no visits and no BP", registration_facility: facility)

      patient_with_bp = create(:patient, registration_facility: facility)
      _appointment_1 = create(:appointment, creation_facility: facility, scheduled_date: may_1, device_created_at: may_1, patient: patient_visited_via_appt)
      _appointment_2 = create(:appointment, creation_facility: facility, scheduled_date: may_15, device_created_at: may_15, patient: patient_with_bp)
      _appointment_3 = create(:appointment, creation_facility: facility, scheduled_date: may_15, device_created_at: may_15, patient: patient_visited_via_appt)
      create(:blood_pressure, :under_control, facility: facility, patient: patient_with_bp, recorded_at: may_15)
      patient_from_different_facility = FactoryBot.create(:patient, registration_facility: facility_2)
      _appointment_4 = create(:appointment, creation_facility: facility_2, scheduled_date: may_15, device_created_at: may_15, patient: patient_from_different_facility)
    end

    range = (Period.month("October 1 2018")..Period.month("October 1 2020"))
    results = NoBPMeasureService.new(facility, periods: range).call
    months_with_visits = ["May 2020", "June 2020", "July 2020"].map { |str| Period.month(str) }
    entries_with_visits, entries_without_visits = results.partition { |key, period| key.in?(months_with_visits) }
    entries_with_visits.each do |(period, count)|
      expect(count).to eq(4)
    end
    entries_without_visits.each do |(period, count)|
      expect(count).to eq(0)
    end
  end
end
