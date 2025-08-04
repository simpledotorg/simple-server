require "rails_helper"

describe DrRai::StatinsQuery do
  let(:district) { setup_district_with_facilities }
  let(:region) { district[:region] }

  around do |xmpl|
    with_reporting_time_zone { xmpl.run }
  end

  describe "transform" do
    let(:valid_data) { CSV.read("spec/data/mock_statins_query_result.csv") }
    let(:valid_db_result) { ActiveRecord::Result.new(valid_data[0], valid_data.drop(1)) }

    it "changes db-row format to dashboard format" do
      # from
      # month_date, aggregate_root, eligible_statins_patients, patients_prescribed_statins, percentage_statin_patients
      # August 1 2025, facility_1, 2259, 1688, 74.72
      # to
      # {
      #   "facility_1": {
      #     <Period value: "Q2-2025">: {
      #       eligible_statins_patients: 2258,
      #       patients_prescribed_statins: 1688,
      #     }
      #   }
      # }
      query = described_class.new(region)
      allow(query).to receive(:db_results).and_return(valid_db_result)
      actual = query.transform!
      expect(actual.keys).to all(be_a(String))
      actual[actual.keys.first].each do |k, v|
        expect(k).to be_a(Period)
        expect(v.keys).to all(be_a(Symbol))
        expect(v.values).to all(be_a(Integer))
      end
    end

    it "properly tallies up quarter numbers" do
      query = described_class.new(region)
      allow(query).to receive(:db_results).and_return(valid_db_result)
      actual = query.transform!
      eligible_statins_patients_numbers = actual["facility_1"].map { |_, v| v[:eligible_statins_patients] }
      expect(eligible_statins_patients_numbers).to eq [4533, 6233, 1946]
    end
  end
end
