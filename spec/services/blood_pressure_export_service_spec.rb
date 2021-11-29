require "rails_helper"

RSpec.describe BloodPressureExportService, type: :model do
  let(:organization) { Seed.seed_org }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:small_facility) { create(:facility, name: "small1", facility_group: facility_group, facility_size: "small") }
  let(:december) { Date.parse("Dec-2020").beginning_of_month }
  let(:may) { Date.parse("May-2021").beginning_of_month }
  let(:start_period) { Period.month(december) }
  let(:end_period) { Period.month(may) }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:supervisor) { create(:admin, :manager, :with_access, resource: facility_group) }

  before :each do
    I18n.default_locale = :en_IN
  end

  describe "#call" do
    context "when data is downloaded" do
      Flipper.enable(:my_facilities_csv)
      it "formats as expected" do
        facility_1 = create(:facility, name: "facility_1", facility_group: facility_group, facility_size: "small")
        facility_2 = create(:facility, name: "facility_2", facility_group: facility_group, facility_size: "medium")
        facility_3 = create(:facility, name: "facility_3", facility_group: facility_group, facility_size: "large")
        facility_4 = create(:facility, name: "facility_4", facility_group: facility_group, facility_size: "large")

        patients = create_list(:patient, 2, full_name: "patient", registration_user: user, registration_facility: facility_3, recorded_at: may - 5.months)
        patients.each { |p| create(:bp_with_encounter, :under_control, facility: facility_3, patient: p) }

        facility_set_1 = [facility_1, facility_2, facility_3]
        facility_set_2 = [facility_1, facility_3, facility_4]

        refresh_views

        service_1 = described_class.new(start_period: start_period, end_period: end_period, facilities: facility_set_1)
        service_2 = described_class.new(start_period: start_period, end_period: end_period, facilities: facility_set_2)
        debugger
        expect(service_1.call.keys).to eq(["large", "medium", "small"])
        expect(service_2.call.keys).to eq(["large", "small"])
        expect(service_1.call.values.first.keys).to eq(["aggregate", "facilities"])
        expect(service_1.call["large"]["aggregate"]["Total registered"]).to eq("2")
      end
    end
  end

  # let(:organization) { Seed.seed_org }
  # let(:facility_group) { create(:facility_group, organization: organization) }
  # # let(:small_facility) { create(:facility, name: "small1", facility_group: facility_group, facility_size: "small") }
  # let(:december) { Date.parse("Dec-2020").beginning_of_month }
  # let(:may) { Date.parse("May-2021").beginning_of_month }
  # let(:start_period) { Period.month(december) }
  # let(:end_period) { Period.month(may) }
  # let(:period_range) { (start_period..end_period).to_a }
  # let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }

  # before :each do
  #   I18n.default_locale = :en_IN
  # end

  # describe "#call" do # state what you want to test
  #   context "when data is downloaded" do # more for data setup
  #     Flipper.enable(:my_facilities_csv)
  #     it "processes results for small facilities" do
  #       small_facility1 = create(:facility, name: "small_1", facility_group: facility_group, facility_size: "small")
  #       small_facility2 = create(:facility, name: "small_2", facility_group: facility_group, facility_size: "small")
  #       small_controlled = create_list(:patient, 2, full_name: "small_controlled", registration_user: user,
  #                                                   registration_facility: small_facility1, recorded_at: may - 5.months)
  #       small_uncontrolled = create(:patient, full_name: "small_uncontrolled", registration_facility: small_facility2,
  #                                             recorded_at: may - 5.months, registration_user: user)
  #       # recorded_at needs to be in a month after registration in order to appear in control rate data

  #       facilities = [small_facility1, small_facility2]

  #       refresh_views

  #       service = described_class.new(start_period: start_period, end_period: end_period, facilities: facilities)
  #       csv = service.as_csv
  #       expect(csv).to_not be_nil
  #       rows = CSV.parse(csv, headers: true)
  #       expect(rows[0]["BP controlled"]).to eq("6 month change") # We have two rows of headers, and the 6 mo change header is the 2nd header underneath the "BP Controlled" piece
  #       expect(rows[1]["Facilities"]).to eq("All PHCs")
  #       expect(rows[1]["Total registered"]).to eq("3")
  #       expect(rows[2]["Facilities"]).to eq("Small_1")
  #       expect(rows[3]["Facilities"]).to eq("Small_2")
  #     end

  #     it "processes results for medium sized facilities" do
  #       medium_facility1 = create(:facility, name: "medium_1", facility_size: "medium", facility_group: facility_group)
  #       medium_facility2 = create(:facility, name: "medium_2", facility_size: "medium", facility_group: facility_group)
  #       medium_controlled = create_list(:patient, 2, full_name: "medium_controlled", registration_facility: medium_facility1,
  #                                                    recorded_at: may - 4.months, registration_user: user)
  #       medium_uncontrolled = create(:patient, full_name: "medium_uncontrolled", registration_facility: medium_facility2,
  #                                              recorded_at: may - 4.months, registration_user: user)

  #       medium_controlled.each do |patient|
  #         logger.info "--- start"
  #         create(:blood_pressure, :under_control, patient: patient, facility: patient.assigned_facility,
  #                                                 recorded_at: may - 4.months, user: user)
  #         logger.info "--- end"
  #       end

  #       create(:blood_pressure, :hypertensive, patient: medium_uncontrolled, facility: medium_uncontrolled.assigned_facility,
  #                                              recorded_at: may - 4.months, user: user)

  #       facilities = [medium_facility1, medium_facility2]

  #       service = described_class.new(start_period: start_period, end_period: end_period, facilities: facilities)
  #       result = service.call

  #       expected_results = {"medium" =>
  #         {"aggregate" =>
  #           {"Facilities" => "All CHCs",
  #            "Total assigned" => "3",
  #            "Total registered" => "3",
  #            "Six month change" => "0%",
  #            period_range[0] => "0%",
  #            "Dec-2020-ratio" => "0 / 0",
  #            period_range[1] => "0%",
  #            "Jan-2021-ratio" => "0 / 0",
  #            period_range[2] => "0%",
  #            "Feb-2021-ratio" => "0 / 0",
  #            period_range[3] => "0%",
  #            "Mar-2021-ratio" => "0 / 0",
  #            period_range[4] => "0%",
  #            "Apr-2021-ratio" => "0 / 3",
  #            period_range[5] => "0%",
  #            "May-2021-ratio" => "0 / 3"},
  #          "facilities" =>
  #           [{"Facilities" => "Medium_1",
  #             "Total assigned" => "2",
  #             "Total registered" => "2",
  #             "Six month change" => "0%",
  #             period_range[0] => "0%",
  #             "Dec-2020-ratio" => "0 / 0",
  #             period_range[1] => "0%",
  #             "Jan-2021-ratio" => "0 / 0",
  #             period_range[2] => "0%",
  #             "Feb-2021-ratio" => "0 / 0",
  #             period_range[3] => "0%",
  #             "Mar-2021-ratio" => "0 / 0",
  #             period_range[4] => "0%",
  #             "Apr-2021-ratio" => "0 / 2",
  #             period_range[5] => "0%",
  #             "May-2021-ratio" => "0 / 2"},
  #             {"Facilities" => "Medium_2",
  #              "Total assigned" => "1",
  #              "Total registered" => "1",
  #              "Six month change" => "0%",
  #              period_range[0] => "0%",
  #              "Dec-2020-ratio" => "0 / 0",
  #              period_range[1] => "0%",
  #              "Jan-2021-ratio" => "0 / 0",
  #              period_range[2] => "0%",
  #              "Feb-2021-ratio" => "0 / 0",
  #              period_range[3] => "0%",
  #              "Mar-2021-ratio" => "0 / 0",
  #              period_range[4] => "0%",
  #              "Apr-2021-ratio" => "0 / 1",
  #              period_range[5] => "0%",
  #              "May-2021-ratio" => "0 / 1"}]}}

  #       expect(result).to eq(expected_results)
  #     end

  #     it "processes results for large sized facilities" do
  #       # large_facility1 = create(:facility, name: "large_1", facility_size: "large", facility_group: facility_group)
  #       # large_facility2 = create(:facility, name: "large_2", facility_size: "large", facility_group: facility_group)
  #       # large_controlled = create(:patient, full_name: "large_controlled", registration_user: user,
  #       #                                     registration_facility: large_facility1, recorded_at: may - 3.months)
  #       # expect(large_controlled.registration_facility).to eq(large_controlled.assigned_facility)
  #       # large_uncontrolled = create_list(:patient, 2, full_name: "large_uncontrolled", registration_user: user,
  #       #                                               registration_facility: large_facility2, recorded_at: may - 3.months)
  #       # create(:blood_pressure, :under_control, patient: large_controlled, user: user,
  #       #                                         facility: large_controlled.assigned_facility, recorded_at: may - 2.months)
  #       # large_uncontrolled.each do |patient|
  #       #   create(:blood_pressure, :hypertensive, patient: patient, user: user,
  #       #                                          facility: patient.assigned_facility, recorded_at: may - 2.months)
  #       # end
  #     end

  #     it "processes community sized facilities"

  #     it "omits sizes that are not represented in the facilities data"

  #     it "processes bp controlled"

  #     it "processes bp uncontrolled"

  #     it "processes missed visits"
  #   end
  # end

  # describe "#as_csv" do
  #   it "returns a csv object with expected data"
  # end
end
