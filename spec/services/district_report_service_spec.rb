require "rails_helper"

describe DistrictReportService, type: :model do
  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerDay.refresh
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
      LatestBloodPressuresPerPatient.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  it "retrieves controlled patient counts for district" do
    user = create(:user)
    facility_group = FactoryBot.create(:facility_group, name: "Darrang")
    facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group)
    facility = facilities.first

    Timecop.freeze(Time.parse("February 15th 2020")) do
      other_patients = create_list(:patient, 2, recorded_at: 1.month.ago, registration_facility: facility, registration_user: user)
      other_patients.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.current)
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.current)
      end
    end

    Timecop.freeze("April 15th 2020") do
      patients_with_controlled_bp = create_list(:patient, 2, recorded_at: 1.month.ago, registration_facility: facility, registration_user: user)
      patients_with_controlled_bp.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.current)
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.current)
      end
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
    expect(result[:controlled_patients]["Jan 2020"]).to eq(2)
    expect(result[:controlled_patients]["Feb 2020"]).to eq(0)
    expect(result[:controlled_patients]["Mar 2020"]).to eq(2)

    expect(result[:registrations]["Jan 2020"]).to eq(2)
    expect(result[:registrations]["May 2020"]).to eq(4)
    expect(result[:cumulative_registrations]).to eq(4)
  end
end
