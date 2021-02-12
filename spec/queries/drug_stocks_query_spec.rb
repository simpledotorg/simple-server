require "rails_helper"

RSpec.describe DrugStocksQuery do
  let!(:state) { "Punjab" }
  let!(:protocol) { create(:protocol, :with_tracked_drugs) }
  let!(:facility_group) { create(:facility_group, protocol: protocol) }
  let!(:user) { create(:admin, :manager, :with_access, resource: facility_group) }
  let!(:for_end_of_month) { Date.today.end_of_month }
  let!(:drug_category) { "hypertension_ccb" }
  let!(:stocks_by_rxnorm) {
    {"329528" => 10000, "329526" => 20000, "316764" => 10000, "316765" => 20000, "979467" => 10000}
  }
  let!(:punjab_drug_stock_config) {
    {"load_coefficient" => 1,
     "drug_categories" =>
        {"hypertension_ccb" => {"new_patient_coefficient" => 1.4, "329528" => 1.2, "329526" => 2},
         "hypertension_arb" => {"new_patient_coefficient" => 0.37, "316764" => 1, "316765" => 2, "979467" => 1},
         "hypertension_diuretic" => {"new_patient_coefficient" => 0.06, "316049" => 1, "331132" => 1}}}.with_indifferent_access
  }

  describe "#drug_stock_for_facility" do
    let!(:facility) { create(:facility, facility_group: facility_group, state: state) }
    let!(:patients) { create_list(:patient, 3, registration_facility: facility, registration_user: user) }

    let!(:drug_stocks) {
      stocks_by_rxnorm.map do |(rxnorm_code, in_stock)|
        protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
        create(:drug_stock, user: user, facility: facility, protocol_drug: protocol_drug, in_stock: in_stock)
      end
    }

    before do
      allow_any_instance_of(Reports::PatientDaysCalculation).to receive(:patient_days_coefficients).and_return(punjab_drug_stock_config)
    end

    it "computes the report for a given facility" do
      instance = described_class.new(facilities: [facility], for_end_of_month: for_end_of_month)
      result = instance.drug_stock_for_facility(facility, drug_stocks)
      {"hypertension_ccb" => %w[329528 329526],
       "hypertension_arb" => %w[316764 316765 979467]}.each do |(drug_category, rxnorm_codes)|
        expected_drug_stocks = drug_stocks.select { |drug_stock| rxnorm_codes.include? drug_stock.protocol_drug.rxnorm_code }
        expect(result[drug_category][:drug_stocks].values).to match_array(expected_drug_stocks)
        expect(result[drug_category][:patient_count]).to eq(patients.count)
        expect(result[drug_category][:load_coefficient]).not_to be_nil
        expect(result[drug_category][:new_patient_coefficient]).not_to be_nil
        expect(result[drug_category][:estimated_patients]).not_to be_nil
        expect(result[drug_category][:patient_days]).not_to be_nil
      end

      expect(result["hypertension_ccb"][:patient_days]).to eq(12380)
      expect(result["hypertension_ccb"][:patient_count]).to eq(patients.count)

      expect(result["hypertension_arb"][:patient_days]).to eq(54054)
      expect(result["hypertension_arb"][:patient_count]).to eq(patients.count)
    end

    it "skips drug categories when drug stocks are not present" do
      instance = described_class.new(facilities: [facility], for_end_of_month: for_end_of_month)
      result = instance.drug_stock_for_facility(facility, drug_stocks)

      expect(result["hypertension_diuretic"]).to eq(nil)
    end

    it "skips computing drug stock report when there are no drug stocks or patients for a facility" do
      facility_without_drug_stocks = create(:facility, facility_group: facility.facility_group)

      instance = described_class.new(facilities: [facility_without_drug_stocks], for_end_of_month: for_end_of_month)
      result = instance.drug_stock_for_facility(facility_without_drug_stocks, drug_stocks)

      expect(result[:facility]).to eq(facility_without_drug_stocks)
      expect(result[:patient_count]).to eq(0)
    end
  end

  describe "#totals" do
    let!(:facilities) { create_list(:facility, 3, facility_group: facility_group, state: state) }

    let!(:patients) {
      facilities.map { |facility|
        create_list(:patient, 3, registration_facility: facility, registration_user: user)
      }.flatten
    }

    let!(:drug_stocks) {
      facilities.map { |facility|
        stocks_by_rxnorm.map do |(rxnorm_code, in_stock)|
          protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
          create(:drug_stock, user: user, facility: facility, protocol_drug: protocol_drug, in_stock: in_stock)
        end
      }.flatten
    }

    before do
      allow_any_instance_of(Reports::PatientDaysCalculation).to receive(:patient_days_coefficients).and_return(punjab_drug_stock_config)
    end

    it "computes totals correctly for a given list of facilities" do
      instance = described_class.new(facilities: facilities, for_end_of_month: for_end_of_month)
      result = instance.totals
      expect(result[:patient_count]).to eq(patients.count)
      expect(result["hypertension_ccb"][:patient_days]).to eq(12380)
      expect(result["hypertension_arb"][:patient_days]).to eq(54054)

      {"hypertension_ccb" => %w[329528 329526],
       "hypertension_arb" => %w[316764 316765 979467]}.each do |(drug_category, rxnorm_codes)|
        expect(result[drug_category][:patient_count]).to eq(patients.count)
        expect(result[drug_category][:load_coefficient]).not_to be_nil
        expect(result[drug_category][:new_patient_coefficient]).not_to be_nil
        expect(result[drug_category][:estimated_patients]).not_to be_nil

        rxnorm_codes.each do |rxnorm_code|
          protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
          expected_total_stock = stocks_by_rxnorm[rxnorm_code] * facilities.count
          expect(result[drug_category][:drug_stocks][protocol_drug.id]).to eq(expected_total_stock)
        end
      end
    end

    it "computes totals correctly for facilities without drug stock" do
      instance = described_class.new(facilities: facilities, for_end_of_month: for_end_of_month)
      result = instance.totals
      expect(result[:patient_count]).to eq(patients.count)
      expect(result["hypertension_diuretic"]).to be_nil
    end
  end

  describe "#cache_key" do
    it "caches for a given set of facilities and month" do
      facilities = create_list(:facility, 3, facility_group: facility_group)

      ck_this_month = described_class.new(facilities: facilities, for_end_of_month: Date.today.end_of_month).cache_key
      ck_next_month = described_class.new(facilities: facilities, for_end_of_month: 1.month.from_now.end_of_month).cache_key
      expect(ck_this_month).not_to eq(ck_next_month)

      facility = create(:facility, facility_group: facility_group)
      ck_this_month_with_facility = described_class.new(facilities: facilities << facility, for_end_of_month: Date.today.end_of_month).cache_key
      expect(ck_this_month).not_to eq(ck_this_month_with_facility)
    end
  end
end
