require "rails_helper"

RSpec.describe BloodPressureExportService, type: :model do
  let(:organization) { Seed.seed_org }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:small_facility) { create(:facility, name: "small1", facility_group: facility_group, facility_size: "small") }
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
        service = described_class.new(data_type: "bp_controlled", start_period: start_period, end_period: end_period, facilities: [small_facility])
        result = service.call
        expect(result).to eq({})
      end
    end
  end


end