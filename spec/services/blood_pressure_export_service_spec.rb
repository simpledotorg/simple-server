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
        expect(service_1.call.keys).to eq(["large", "medium", "small"])
        expect(service_2.call.keys).to eq(["large", "small"])
        expect(service_1.call.values.first.keys).to eq(["aggregate", "facilities"])
        expect(service_1.call["large"]["aggregate"]["Total registered"]).to eq("2")
      end
    end
  end
end
