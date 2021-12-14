require "rails_helper"

RSpec.describe BloodPressureExportService, type: :model do
  let(:organization) { Seed.seed_org }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:start_period) { Period.month("December 1st 2020") }
  let(:end_period) { Period.month("May 1st 2021") }

  before :each do
    I18n.default_locale = :en_IN
    Flipper.enable(:my_facilities_csv)
  end

  describe "#call" do
    context "when data is downloaded" do
      it "formats as expected" do
        facility_1 = create(:facility, name: "facility_1", facility_group: facility_group, facility_size: "small")
        facility_2 = create(:facility, name: "facility_2", facility_group: facility_group, facility_size: "medium")
        facility_3 = create(:facility, name: "facility_3", facility_group: facility_group, facility_size: "large")
        facility_4 = create(:facility, name: "facility_4", facility_group: facility_group, facility_size: "large")

        patients = create_list(:patient, 2, full_name: "patient", registration_user: user, registration_facility: facility_3, recorded_at: Time.zone.parse("January 1st 2021 12:00:00"))
        patients.each { |p| create(:bp_with_encounter, :under_control, facility: facility_3, patient: p, user: user) }

        facility_set_1 = [facility_1, facility_2, facility_3]
        facility_set_2 = [facility_1, facility_3, facility_4]

        refresh_views

        result_1 = described_class.new(start_period: start_period, end_period: end_period, facilities: facility_set_1).call
        expect(result_1.keys).to eq(["large", "medium", "small"])
        expect(result_1.values.first.keys).to eq(["aggregate", "facilities"])
        expect(result_1["large"]["aggregate"]["Total registered"]).to eq("2")
        expect(result_1["large"]["aggregate"]["Total assigned"]).to eq("2")

        result_2 = described_class.new(start_period: start_period, end_period: end_period, facilities: facility_set_2).call
        expect(result_2.keys).to eq(["large", "small"])
        expect(result_2["large"]["aggregate"]["Total registered"]).to eq("2")
        expect(result_2["large"]["aggregate"]["Total assigned"]).to eq("2")
      end
    end
  end
end
