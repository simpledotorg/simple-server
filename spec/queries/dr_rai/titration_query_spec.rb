require "rails_helper"

describe DrRai::TitrationQuery do
  let(:district) { setup_district_with_facilities }
  let(:region) { district[:region] }

  around do |xmpl|
    with_reporting_time_zone { xmpl.run }
  end

  describe "valid structure" do
    let(:valid_data) { CSV.read("spec/data/mock_titration_query_result.csv") }
    let(:valid_db_result) { ActiveRecord::Result.new(valid_data[0], valid_data.drop(1)) }

    it "should use the csv as output" do
      expect(described_class.new(region).valid_structure?(valid_db_result)).to be_truthy
    end
  end

  describe "period for" do
    it "throws errors for non-string dates" do
      expect { described_class.new(region).period_for(Date.today) }.to raise_error(RuntimeError, "Dates must be a String")
    end

    it "transforms string dates in a specific format to Period" do
      titration_query = described_class.new(region)

      expect(titration_query.period_for("May 1, 2025").value).to eq("Q2-2025")
    end
  end

  describe "transform" do
    let(:valid_data) { CSV.read("spec/data/mock_titration_query_result.csv") }
    let(:valid_db_result) { ActiveRecord::Result.new(valid_data[0], valid_data.drop(1)) }

    it "changes db-row format to dashboard format" do
      # from
      # facility_name, uncontrolled, titrated, not_titrated, percent_titrated, month_date
      # Addisalem Primary Hospital, 120, 14, 106, 11.67, May 1 2025
      # to
      # {
      #   <Period value: "Q2-2025">: {
      #     "Addisalem Primary Hospital": {
      #       uncontrolled: 120,
      #       titrated: 14,
      #       not_titrated: 106,
      #     }
      #   }
      # }
      query = described_class.new(region)
      allow(query).to receive(:db_results).and_return(valid_db_result)
      actual = query.transform!
      expect(actual.size).to eq 1
      period = Period.quarter("May 1, 2025")
      expect(actual[period].size).to eq 4
    end
  end
end
