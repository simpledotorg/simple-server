require "rails_helper"

RSpec.describe BloodPressureExportService, type: :model do
  let(:organization) { Seed.seed_org }
  let(:facility_group) { create(:facility_group, organization: organization) }
  # let(:small_facility) { create(:facility, name: "small1", facility_group: facility_group, facility_size: "small") }
  let(:december) { Date.parse("12-01-2020").beginning_of_month }
  let(:may) { Date.parse("5-01-2021").beginning_of_month }
  let(:start_period) { Period.month(december) }
  let(:end_period) { Period.month(may) }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  describe "#call" do #more for a thing
    context "when data_type is bp_controlled" do # more for data setup
      it "creates data in the expected format" do
        small_facility1 = create(:facility, name: "small_1", facility_group: facility_group, facility_size: "small")
        small_facility2 = create(:facility, name: "small_2", facility_group: facility_group, facility_size: "small")
        small_controlled = create_list(:patient, 2, full_name: "small_controlled", registration_user: user,
                                                    registration_facility: small_facility1, recorded_at: december - 5.months)
        small_uncontrolled = create(:patient, full_name: "small_uncontrolled", registration_facility: small_facility2,
                                              recorded_at: december - 5.months, registration_user: user)
        # recorded_at needs to be in a month after registration in order to appear in control rate data
        small_controlled.each do |patient|
          logger.info "--- start"
          create(:blood_pressure, :under_control, patient: patient, facility: patient.assigned_facility,
                                                  recorded_at: december - 4.months, user: user)
          logger.info "--- end"
        end
        create(:blood_pressure, :hypertensive, patient: small_uncontrolled, facility: small_uncontrolled.assigned_facility,
                                               recorded_at: december - 4.months, user: user)

        medium_facility1 = create(:facility, name: "medium_1", facility_size: "medium", facility_group: facility_group)
        medium_facility2 = create(:facility, name: "medium_2", facility_size: "medium", facility_group: facility_group)
        medium_controlled = create(:patient, full_name: "medium_controlled", registration_facility: medium_facility1,
                                             recorded_at: december - 4.months, registration_user: user)
        medium_uncontrolled = create(:patient, full_name: "medium_uncontrolled", registration_facility: medium_facility2,
                                               recorded_at: december - 4.months, registration_user: user)
        create(:blood_pressure, :under_control, patient: medium_controlled, user: user,
                                                facility: medium_controlled.assigned_facility, recorded_at: december - 3.months)
        create(:blood_pressure, :hypertensive, patient: medium_uncontrolled, user: user,
                                               facility: medium_controlled.assigned_facility, recorded_at: december - 3.months)

        large_facility1 = create(:facility, name: "large_1", facility_size: "large", facility_group: facility_group)
        large_facility2 = create(:facility, name: "large_2", facility_size: "large", facility_group: facility_group)
        large_controlled = create(:patient, full_name: "large_controlled", registration_user: user,
                                            registration_facility: large_facility1, recorded_at: december - 3.months)
        expect(large_controlled.registration_facility).to eq(large_controlled.assigned_facility)
        large_uncontrolled = create_list(:patient, 2, full_name: "large_uncontrolled", registration_user: user,
                                                      registration_facility: large_facility2, recorded_at: december - 3.months)
        create(:blood_pressure, :under_control, patient: large_controlled, user: user,
                                                facility: large_controlled.assigned_facility, recorded_at: december - 2.months)
        large_uncontrolled.each do |patient|
          create(:blood_pressure, :hypertensive, patient: patient, user: user,
                                                 facility: patient.assigned_facility, recorded_at: december - 2.months)
        end

        facilities = [small_facility1, small_facility2, medium_facility1, medium_facility2, large_facility1, large_facility2]
        service = described_class.new(data_type: "bp_controlled", start_period: start_period, end_period: end_period, facilities: facilities, facility_sizes: ["small"])
        result = service.call

        expected_results = {
          small: {

          }
        }
        expect(result).to eq(expected)
      end

      it "omits sizes that are not represented in the facilities data"
    end
  end


end