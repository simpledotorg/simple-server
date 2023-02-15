require "rails_helper"

describe BangladeshDhis2Exporter do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:regions) { setup_district_with_facilities }
  let(:period) { Period.current }

  describe "#data" do
    it "contains count of cumulative assigned patients disaggregated by gender and age in a facility as of the given period" do
      _facility_1_patient_1 = create(:patient, assigned_facility: regions[:facility_1], gender: :male, age: 63)
      _facility_1_patient_2 = create(:patient, assigned_facility: regions[:facility_1], gender: :female, age: 48)
      refresh_views

      expect(BangladeshDhis2Exporter
               .new(regions[:facility_1].region, period)
               .data[:cumulative_assigned_patients])
        .to eq({["female", 7] => 1, ["male", 10] => 1})
    end

    it "contains count of controlled patients disaggregated by gender and age in a facility as of the given period" do
      _facility_1_patient_1 = create(:patient, :controlled, assigned_facility: regions[:facility_1], gender: :male, age: 63)
      _facility_1_patient_2 = create(:patient, :controlled, assigned_facility: regions[:facility_1], gender: :female, age: 30)
      _facility_1_patient_3 = create(:patient, :uncontrolled, assigned_facility: regions[:facility_1], gender: :female, age: 48)
      refresh_views

      expect(BangladeshDhis2Exporter
               .new(regions[:facility_1].region, period)
               .data[:controlled_patients])
        .to eq({["female", 4] => 1, ["male", 10] => 1})
    end
  end
end
