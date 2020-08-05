require "rails_helper"

RSpec.describe VisitedButNoBPService do
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
      LatestBloodPressuresPerPatientPerQuarter.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  it "counts visits for appts, drugs updated, blood sugar taken without blood pressures" do
    may_1 = Time.parse("May 1st, 2020")
    may_15 = Time.parse("May 15th, 2020")
    august_1 = Time.parse("August 1st 2020")
    facility = create(:facility, facility_group: facility_group_1)
    facility_2 = create(:facility)
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

    periods = (Period.month(may_1)..Period.month(august_1))
    service = VisitedButNoBPService.new(facility, periods: periods)
    (Period.month(may_1)..Period.month(august_1)).each do |period|
      result = service.patients_visited_with_no_bp_taken(period)
      expect(result).to_not include(patient_with_bp, patient_without_visit_and_bp)
      expect(result).to include(patient_visited_via_appt, patient_visited_via_drugs, patient_visited_via_blood_sugar)
    end
    results = service.call
    results.each do |period, count|
      expect(count).to eq(3)
    end
  end

end