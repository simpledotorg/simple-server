require "rails_helper"

RSpec.describe Reports::DrugStockCalculation, type: :model do
  let(:state) { "Punjab" }
  let(:protocol) { FactoryBot.create(:protocol, :with_tracked_drugs) }
  let(:protocol_drugs) { protocol.protocol_drugs }
  let(:facility_group) { FactoryBot.create(:facility_group, protocol: protocol) }
  let(:facility) { FactoryBot.create(:facility, facility_group: facility_group, state: state) }
  let(:user) { create(:admin) }
  let(:drug_category) { "hypertension_ccb" }
  let(:drug_stocks) {
    [build(:drug_stock, in_stock: 10000, received: 5000, redistributed: 1000, facility: facility, user: user, protocol_drug: protocol_drugs.find_by(rxnorm_code: "329528")),
      build(:drug_stock, in_stock: 20000, received: 20000, redistributed: 500, facility: facility, user: user, protocol_drug: protocol_drugs.find_by(rxnorm_code: "329526")),
      build(:drug_stock, in_stock: 10000, redistributed: 0, facility: facility, user: user, protocol_drug: protocol_drugs.find_by(rxnorm_code: "316764")),
      build(:drug_stock, in_stock: 20000, redistributed: 0, facility: facility, user: user, protocol_drug: protocol_drugs.find_by(rxnorm_code: "316765")),
      build(:drug_stock, in_stock: 10000, redistributed: 0, facility: facility, user: user, protocol_drug: protocol_drugs.find_by(rxnorm_code: "979467")),
      build(:drug_stock, in_stock: 10000, redistributed: 0, facility: facility, user: user, protocol_drug: protocol_drugs.find_by(rxnorm_code: "316049")),
      build(:drug_stock, in_stock: 10000, redistributed: 0, facility: facility, user: user, protocol_drug: protocol_drugs.find_by(rxnorm_code: "331132"))]
  }
  let(:previous_month_drug_stocks) {
    [build(:drug_stock, in_stock: 10000, facility: facility, user: user, protocol_drug: protocol_drugs.find_by(rxnorm_code: "329528")),
      build(:drug_stock, in_stock: 10000, facility: facility, user: user, protocol_drug: protocol_drugs.find_by(rxnorm_code: "329526"))]
  }

  let(:punjab_drug_stock_config) {
    {"load_coefficient" => 1,
     "drug_categories" =>
        {"hypertension_ccb" => {"new_patient_coefficient" => 1.4, "329528" => 1.2, "329526" => 2},
         "hypertension_arb" => {"new_patient_coefficient" => 0.37, "316764" => 1, "316765" => 2, "979467" => 1},
         "hypertension_diuretic" => {"new_patient_coefficient" => 0.06, "316049" => 1, "331132" => 1}}}.with_indifferent_access
  }
  let(:patient_count) { 10000 }

  describe "#stocks_on_hand" do
    before do
      allow_any_instance_of(described_class).to receive(:patient_days_coefficients).and_return(punjab_drug_stock_config)
    end

    it "calculates correctly when it has all drug stocks, and protocol and formula are cohesive" do
      result = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks,
        patient_count: patient_count
      ).stocks_on_hand

      expect(result).to match_array [
        {protocol_drug: protocol_drugs.find_by(rxnorm_code: "329528"),
         in_stock: 10000,
         coefficient: 1.2,
         stock_on_hand: 12000},
        {protocol_drug: protocol_drugs.find_by(rxnorm_code: "329526"),
         in_stock: 20000,
         coefficient: 2,
         stock_on_hand: 40000}
      ]
    end

    it "ignores a drug in protocol that is not in formula" do
      FactoryBot.create(:protocol_drug, protocol: protocol, drug_category: drug_category, stock_tracked: true)
      result = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks,
        patient_count: patient_count
      ).stocks_on_hand
      expect(result.map { |stock_on_hand| stock_on_hand[:protocol_drug].rxnorm_code }).to match_array ["329528", "329526"]
    end

    it "ignores a drug in formula that is not in protocol" do
      drug_stock_config = punjab_drug_stock_config
      drug_stock_config["drug_categories"]["hypertension_ccb"] = {
        "new_patient_coefficient" => 1.4,
        "329528" => 1.2,
        "329526" => 2,
        "unknown_rx_norm" => 19
      }.with_indifferent_access
      allow_any_instance_of(described_class).to receive(:patient_days_coefficients).and_return(drug_stock_config)
      result = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks,
        patient_count: patient_count
      ).stocks_on_hand
      expect(result.map { |stock_on_hand| stock_on_hand[:protocol_drug].rxnorm_code }).to match_array ["329528", "329526"]
    end

    it "ignores a drug for which the stock is unknown" do
      result = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks.drop(1),
        patient_count: patient_count
      ).stocks_on_hand
      expect(result.map { |stock_on_hand| stock_on_hand[:protocol_drug].rxnorm_code }).to match_array ["329526"]
    end

    it "returns a empty list when stock is not available for any drug" do
      result = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: [],
        patient_count: patient_count
      ).stocks_on_hand
      expect(result.map { |stock_on_hand| stock_on_hand[:protocol_drug].rxnorm_code }).to match_array []
    end

    it "computes stock as 0 when all stocks are 0" do
      result = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks.take(2).each { |drug_stock| drug_stock.update(in_stock: 0) },
        patient_count: patient_count
      ).stocks_on_hand
      expect(result.map { |stock_on_hand| stock_on_hand[:stock_on_hand] }).to match_array [0, 0]
    end

    it "errors out when there is no formula for a state" do
      allow_any_instance_of(described_class).to receive(:patient_days_coefficients).and_return(nil)
      instance = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks,
        patient_count: patient_count
      )
      expect { instance.stocks_on_hand }.to raise_error(NoMethodError)
    end
  end

  describe "#patient_days" do
    before do
      allow_any_instance_of(described_class).to receive(:patient_days_coefficients).and_return(punjab_drug_stock_config)
    end
    it "works correctly when all inputs are present" do
      result = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks,
        patient_count: patient_count
      ).patient_days
      expect(result[:load_coefficient]).to eq 1
      expect(result[:new_patient_coefficient]).to eq 1.4
      expect(result[:patient_count]).to eq patient_count
      expect(result[:estimated_patients]).to eq 14000
      expect(result[:patient_days]).to eq ((10000 * 1 + 20000 * 2) / 14000).floor
    end

    it "patient count is nil" do
      result = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks,
        patient_count: nil
      ).patient_days
      expect(result).to eq(patient_days: "error")
    end

    it "patient count is 0" do
      result = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks,
        patient_count: 0
      ).patient_days
      expect(result).to eq(patient_days: "error")
    end

    it "returns an error for patient days when there is no formula for a state" do
      allow_any_instance_of(described_class).to receive(:patient_days_coefficients).and_return(nil)
      result = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks,
        patient_count: patient_count
      ).patient_days
      expect(result).to eq(patient_days: "error")
    end

    it "reports error to datadog" do
      allow_any_instance_of(Datadog::Tracer).to receive(:trace)
      expect_any_instance_of(Datadog::Tracer).to receive(:trace)

      result = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks,
        patient_count: 0
      ).patient_days
      expect(result).to eq(patient_days: "error")
    end
  end

  describe "#patient_days_coefficients" do
    it "returns the first available config when not in production" do
      allow(ENV).to receive(:fetch).and_return("some_other_env")
      allow(Rails.application.config).to receive(:drug_stock_config).and_return({"some_state" => "first config"})
      instance = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks,
        patient_count: 0
      )
      expect(instance.patient_days_coefficients("state_that_does_not_exist")).to eq "first config"
    end

    it "returns the correct config even if nil when in production" do
      allow(ENV).to receive(:fetch).and_return("production")
      allow(Rails.application.config).to receive(:drug_stock_config).and_return({"some_state" => "first config"})
      instance = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks,
        patient_count: 0
      )
      expect(instance.patient_days_coefficients("state_that_does_not_exist")).to eq nil
    end
  end

  describe "#consumption" do
    it "calculates consumption using in_stock, previous month's in_stock, received and redistributed" do
      result = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks,
        previous_drug_stocks: previous_month_drug_stocks,
        patient_count: patient_count
      ).consumption
      drug = protocol_drugs.find_by(rxnorm_code: "329528")

      expect(result[drug][:consumed]).to eq(4000)
      expect(result[drug][:received]).to eq(5000)
      expect(result[drug][:redistributed]).to eq(1000)
    end

    it "calculates consumption using in_stock, previous month's in_stock, received and redistributed" do
      result = described_class.new(
        state: state,
        protocol_drugs: protocol_drugs,
        drug_category: drug_category,
        current_drug_stocks: drug_stocks,
        previous_drug_stocks: previous_month_drug_stocks,
        patient_count: patient_count
      ).consumption
      drug = protocol_drugs.find_by(rxnorm_code: "329526")

      expect(result[drug][:consumed]).to eq(9500)
      expect(result[drug][:received]).to eq(20000)
      expect(result[drug][:redistributed]).to eq(500)
    end
  end
end
