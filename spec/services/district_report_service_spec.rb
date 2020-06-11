require "rails_helper"

describe DistrictReportService, type: :model do
  let!(:facility) { create(:facility) }
  let!(:user) { create(:user) }

  let!(:current_month_start) { Time.current.beginning_of_month }

  let!(:registration_month_start) { current_month_start - 2.months }
  let!(:registration_month) { registration_month_start.month }
  let!(:registration_year) { registration_month_start.year }

  let!(:cohort_range) do
    (registration_month_start.to_date..registration_month_start.end_of_month.to_date).to_a
  end

  let!(:bp_recorded_range) do
    ((current_month_start - 1.months).to_date..Time.current.to_date).to_a
  end

  let!(:current_month_range) do
    (current_month_start.to_date..Time.current.to_date).to_a
  end

  let!(:previous_month_range) do
    ((current_month_start - 1.months).to_date..(current_month_start - 1.months).end_of_month.to_date).to_a
  end

  let!(:patients_with_uncontrolled_bp) do
    [create(:patient, recorded_at: registration_month_start, registration_facility: facility, registration_user: user),
      create(:patient, recorded_at: cohort_range.sample, registration_facility: facility, registration_user: user),
      create(:patient, recorded_at: registration_month_start.end_of_month, registration_facility: facility, registration_user: user)]
  end

  let!(:patients_with_missed_visit) do
    create_list(:patient, 2, recorded_at: cohort_range.sample, registration_facility: facility, registration_user: user)
  end

  let!(:non_htn_patient) do
    create(:patient, :without_hypertension, recorded_at: cohort_range.sample, registration_facility: facility, registration_user: user)
  end

  let!(:uncontrolled_blood_pressures) do
    patients_with_uncontrolled_bp.map do |patient|
      create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: bp_recorded_range.sample, user: user)
    end
  end

  let!(:bps_for_non_htn_patient) do
    [create(:blood_pressure, :under_control, facility: facility, patient: non_htn_patient, recorded_at: current_month_range.sample, user: user),
      create(:blood_pressure, :hypertensive, facility: facility, patient: non_htn_patient, recorded_at: previous_month_range.sample, user: user)]
  end

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerDay.refresh
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
      LatestBloodPressuresPerPatient.refresh
    end
  end

  it "retrieves data for district" do
    user = create(:user)
    facility_group = FactoryBot.create(:facility_group, name: "Darrang")
    facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group)

    Timecop.freeze(4.months.ago) do
      other_patients = create_list(:patient, 2, recorded_at: Time.current, registration_facility: facility, registration_user: user)
      other_patients.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.current)
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.current)
      end
    end

    refresh_views

    patients_with_controlled_bp = create_list(:patient, 2, recorded_at: cohort_range.sample, registration_facility: facility, registration_user: user)
    patients_with_controlled_bp.map do |patient|
      create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: previous_month_range.sample, user: user)
      create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: current_month_range.sample, user: user)
    end

    refresh_views

    june_1 = Date.parse("June 1, 2020")
    service = DistrictReportService.new(facilities: [facility], selected_date: june_1)
    result = service.call

    # @data = {
    #   controlled_patients: {},
    #   registrations: {},
    #   cumulative_registrations: 0,
    #   quarterly_registrations: []
    # }.with_indifferent_access
    expect(result[:controlled_patients].size).to eq(12)
    expect(result[:controlled_patients]["Apr 2020"]).to eq(2)
    p result[:controlled_patients]
  end
end
