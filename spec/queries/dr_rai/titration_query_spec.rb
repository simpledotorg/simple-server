require "rails_helper"

describe DrRai::TitrationQuery do
  let(:district) { setup_district_with_facilities }
  let(:region) { district[:region] }

  around do |xmpl|
    with_reporting_time_zone { xmpl.run }
  end

  describe "valid structure" do
    let(:valid_data) { CSV.read("spec/data/mock_titration_query_result.csv") }
    let(:valid_db_result) { ActiveRecord::Result.new(valid_data.drop(1), valid_data[0]) }

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
end
