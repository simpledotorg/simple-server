require "rails_helper"

RSpec.describe NoBPMeasureService do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :supervisor, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  let(:june_1_2018) { Time.parse("June 1, 2018 00:00:00+00:00") }
  let(:june_1_2020) { Time.parse("June 1, 2020 00:00:00+00:00") }
  let(:june_30_2020) { Time.parse("June 30, 2020 00:00:00+00:00") }
  let(:may_1_2019) { Time.parse("May 1 2019 00:00:00:00+00:00") }
  let(:may_15_2020) { Time.parse("May 15 2020") }
  let(:july_1_2019) { Time.parse("July 1, 2019 00:00:00+00:00") }
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

  it "counts missed visits for 3 month to 1 year window" do
    facility = create(:facility, facility_group: facility_group_1)
    facility_2 = create(:facility)
    patient_visited_one_year_ago_1 = create(:patient, full_name: "visited one year ago 1", registration_facility: facility, recorded_at: Time.parse("June 1st 2019"))
    patient_visited_one_year_ago_1.prescription_drugs << build(:prescription_drug, device_created_at: july_1_2019)
    patient_visited_one_year_ago_2 = create(:patient, full_name: "visited one year ago 2", registration_facility: facility, recorded_at: Time.parse("June 30th 2019"))
    patient_visited_one_year_ago_2.prescription_drugs << build(:prescription_drug, device_created_at: july_1_2019)

    patient_visited_via_drugs = create(:patient, full_name: "visit via drugs Jan 2020", registration_facility: facility)
    patient_visited_via_drugs.prescription_drugs << build(:prescription_drug, device_created_at: Time.parse("January 1st 2020"))
    patient_visited_via_blood_sugar = create(:patient, full_name: "visit via blood sugar Feb 2020", registration_facility: facility)
    patient_visited_via_blood_sugar.blood_sugars << build(:blood_sugar, device_created_at: Time.parse("February 1st 2020"))

    _patient_without_visit_and_bp = create(:patient, full_name: "no visits and no BP", registration_facility: facility)

    patient_with_bp = create(:patient, registration_facility: facility)
    _appointment_2 = create(:appointment, creation_facility: facility, scheduled_date: may_15_2020, device_created_at: may_15_2020, patient: patient_with_bp)
    create(:blood_pressure, :under_control, facility: facility, patient: patient_with_bp, recorded_at: may_15_2020)
    patient_from_different_facility = FactoryBot.create(:patient, registration_facility: facility_2)
    _appointment_4 = create(:appointment, creation_facility: facility_2, scheduled_date: may_15_2020, device_created_at: may_15_2020, patient: patient_from_different_facility)

    periods = (july_2018.to_period..july_2020.to_period) # July 2020 report
    results = NoBPMeasureService.new(facility, periods: periods).call

    expect(results[Period.month("August 1 2019")]).to eq(0)
    expect(results[Period.month("September 1 2019")]).to eq(0)
    # Should the above 'one year old visits' be considered as missed visits for month of October?
    # expect(results[Period.month("October 1 2019")]).to eq(2)
    expect(results[Period.month("November 1 2019")]).to eq(2)
    expect(results[Period.month("April 1 2020")]).to eq(2)
    expect(results[Period.month("July 1 2020")]).to eq(4)
  end

  it "counts lost to followup as patients whose last visit was over 12 months ago" do
    facility = create(:facility, facility_group: facility_group_1)
    patient_1 = create(:patient, registration_facility: facility)
    patient_1.prescription_drugs << build(:prescription_drug, device_created_at: june_1_2018)
    patient_2 = create(:patient, full_name: "no visits and no BP", registration_facility: facility)
    patient_2.appointments << create(:appointment, creation_facility: facility, scheduled_date: may_1_2019, device_created_at: may_1_2019)
    not_lost_1 = create(:patient, registration_facility: facility)
    not_lost_1.blood_sugars << build(:blood_sugar, device_created_at: may_15_2020)
    not_lost_2 = create(:patient, registration_facility: facility)
    not_lost_2.blood_sugars << build(:blood_sugar, device_created_at: Time.find_zone("UTC").parse("July 1st 2019 00:00:00"))

    periods = (july_2018.to_period..july_2020.to_period)
    service = NoBPMeasureService.new(facility, periods: periods, type: :lost_to_folloup)
    results = service.call

    old_visit_results = results.fetch_values(june_1_2020.to_period, july_2020.to_period)
    expect(old_visit_results).to eq([2, 2])
  end
end
