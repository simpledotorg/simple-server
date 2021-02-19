require "rails_helper"

RSpec.describe DrugStocksQuery do
  let!(:state) { "Punjab" }
  let!(:protocol) { create(:protocol, :with_tracked_drugs) }
  let!(:facility_group) { create(:facility_group, protocol: protocol) }
  let!(:user) { create(:admin, :manager, :with_access, resource: facility_group) }
  let!(:for_end_of_month) { Date.today.end_of_month }
  let!(:drug_category) { "hypertension_ccb" }
  let!(:stocks_by_rxnorm) {
    {"329528" => {in_stock: 10000, received: 2000},
     "329526" => {in_stock: 20000, received: 2000},
     "316764" => {in_stock: 10000, received: 2000},
     "316765" => {in_stock: 20000, received: 2000},
     "979467" => {in_stock: 10000, received: 2000}}
  }
  let!(:previous_month_stocks_by_rxnorm) {
    {"329528" => {in_stock: 8000},
     "329526" => {in_stock: 15000},
     "316764" => {in_stock: 8000},
     "316765" => {in_stock: 17000},
     "979467" => {in_stock: 9000}}
  }
  let!(:punjab_drug_stock_config) {
    {"load_coefficient" => 1,
     "drug_categories" =>
        {"hypertension_ccb" => {"new_patient_coefficient" => 1.4, "329528" => 1.2, "329526" => 2},
         "hypertension_arb" => {"new_patient_coefficient" => 0.37, "316764" => 1, "316765" => 2, "979467" => 1},
         "hypertension_diuretic" => {"new_patient_coefficient" => 0.06, "316049" => 1, "331132" => 1}}}.with_indifferent_access
  }

  context "drug stock report" do
    describe "#drug_stock_for_facility" do
      let!(:facility) { create(:facility, facility_group: facility_group, state: state) }
      let!(:patients) { create_list(:patient, 3, registration_facility: facility, registration_user: user) }

      let!(:drug_stocks) {
        stocks_by_rxnorm.map do |(rxnorm_code, drug_stock)|
          protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
          create(:drug_stock,
            user: user,
            facility: facility,
            protocol_drug: protocol_drug,
            in_stock: drug_stock[:in_stock],
            received: drug_stock[:received])
        end
      }

      before do
        allow_any_instance_of(Reports::DrugStockCalculation).to receive(:patient_days_coefficients).and_return(punjab_drug_stock_config)
      end

      it "computes the drug stock report for a given facility" do
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

    describe "#drug_stock_totals" do
      let!(:facilities) { create_list(:facility, 3, facility_group: facility_group, state: state) }

      let!(:patients) {
        facilities.map { |facility|
          create_list(:patient, 3, registration_facility: facility, registration_user: user)
        }.flatten
      }

      let!(:drug_stocks) {
        facilities.map { |facility|
          stocks_by_rxnorm.map do |(rxnorm_code, drug_stock)|
            protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
            create(:drug_stock, user: user, facility: facility, protocol_drug: protocol_drug, in_stock: drug_stock[:in_stock])
          end
        }.flatten
      }

      before do
        allow_any_instance_of(Reports::DrugStockCalculation).to receive(:patient_days_coefficients).and_return(punjab_drug_stock_config)
      end

      it "computes totals correctly for a given list of facilities" do
        instance = described_class.new(facilities: facilities, for_end_of_month: for_end_of_month)
        result = instance.drug_stock_totals
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
            expected_total_stock = stocks_by_rxnorm[rxnorm_code][:in_stock] * facilities.count
            expect(result[drug_category][:drug_stocks][rxnorm_code][:in_stock]).to eq(expected_total_stock)
          end
        end
      end

      it "computes totals correctly for facilities without drug stock" do
        instance = described_class.new(facilities: facilities, for_end_of_month: for_end_of_month)
        result = instance.drug_stock_totals
        expect(result[:patient_count]).to eq(patients.count)
        expect(result["hypertension_diuretic"]).to be_nil
      end
    end

    describe "#drug_stocks_cache_key" do
      it "caches for a given set of facilities and month" do
        facilities = create_list(:facility, 3, facility_group: facility_group)

        ck_this_month = described_class.new(facilities: facilities, for_end_of_month: Date.today.end_of_month).drug_stocks_cache_key
        ck_next_month = described_class.new(facilities: facilities, for_end_of_month: 1.month.from_now.end_of_month).drug_stocks_cache_key
        expect(ck_this_month).not_to eq(ck_next_month)

        facility = create(:facility, facility_group: facility_group)
        ck_this_month_with_facility = described_class.new(facilities: facilities << facility, for_end_of_month: Date.today.end_of_month).drug_stocks_cache_key
        expect(ck_this_month).not_to eq(ck_this_month_with_facility)
      end
    end
  end

  context "drug consumption report" do
    describe "#drug_consumption_for_facility" do
      let!(:facility) { create(:facility, facility_group: facility_group, state: state) }
      let!(:patients) { create_list(:patient, 3, registration_facility: facility, registration_user: user) }

      let!(:drug_stocks) {
        stocks_by_rxnorm.map do |(rxnorm_code, drug_stock)|
          protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
          create(:drug_stock,
            user: user,
            facility: facility,
            protocol_drug: protocol_drug,
            in_stock: drug_stock[:in_stock],
            received: drug_stock[:received])
        end
      }

      let!(:previous_month_drug_stocks) {
        previous_month_stocks_by_rxnorm.map do |(rxnorm_code, drug_stock)|
          protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
          create(:drug_stock,
            user: user,
            facility: facility,
            protocol_drug: protocol_drug,
            in_stock: drug_stock[:in_stock],
            for_end_of_month: (Date.today - 1.month).end_of_month)
        end
      }

      before do
        allow_any_instance_of(Reports::DrugStockCalculation).to receive(:patient_days_coefficients).and_return(punjab_drug_stock_config)
      end

      it "computes the drug consumption report for a given facility" do
        instance = described_class.new(facilities: [facility], for_end_of_month: for_end_of_month)
        result = instance.drug_consumption_for_facility(facility, drug_stocks, previous_month_drug_stocks)
        {"hypertension_ccb" => %w[329528 329526],
         "hypertension_arb" => %w[316764 316765 979467]}.each do |(drug_category, rxnorm_codes)|
          drug_stocks.select { |drug_stock| rxnorm_codes.include? drug_stock.protocol_drug.rxnorm_code }
          expect(result[drug_category][:base_doses][:total]).not_to be_nil
          expect(result[drug_category][:base_doses][:drugs].count).to eq rxnorm_codes.count
          expect(result[drug_category][:base_doses][:drugs].first[:name]).not_to be_nil
          expect(result[drug_category][:base_doses][:drugs].first[:consumed]).not_to be_nil
          expect(result[drug_category][:base_doses][:drugs].first[:coefficient]).not_to be_nil
        end

        expect(result["hypertension_ccb"][:base_doses][:total]).to eq(-6000)
        expect(result["hypertension_arb"][:base_doses][:total]).to eq(-1000)
      end

      it "returns nil base doses when drug stocks are not present" do
        instance = described_class.new(facilities: [facility], for_end_of_month: for_end_of_month)
        result = instance.drug_consumption_for_facility(facility, drug_stocks, previous_month_drug_stocks)

        expect(result["hypertension_diuretic"][:base_doses][:total]).to eq(nil)
      end

      it "computes drug consumption report when there are no drug stocks or patients for a facility" do
        facility_without_drug_stocks = create(:facility, facility_group: facility.facility_group)

        instance = described_class.new(facilities: [facility_without_drug_stocks], for_end_of_month: for_end_of_month)
        result = instance.drug_consumption_for_facility(facility_without_drug_stocks, drug_stocks, previous_month_drug_stocks)

        expect(result[:facility]).to eq(facility_without_drug_stocks)
        expect(result[:patient_count]).to eq(0)
      end
    end

    describe "#drug_consumption_totals" do
      let!(:facilities) { create_list(:facility, 3, facility_group: facility_group, state: state) }

      let!(:patients) {
        facilities.map { |facility|
          create_list(:patient, 3, registration_facility: facility, registration_user: user)
        }.flatten
      }

      let!(:drug_stocks) {
        facilities.map { |facility|
          stocks_by_rxnorm.map do |(rxnorm_code, drug_stock)|
            protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
            create(:drug_stock, user: user, facility: facility, protocol_drug: protocol_drug, in_stock: drug_stock[:in_stock])
          end
        }.flatten
      }

      before do
        allow_any_instance_of(Reports::DrugStockCalculation).to receive(:patient_days_coefficients).and_return(punjab_drug_stock_config)
      end
    end

    describe "#drug_consumption_cache_key" do
      it "caches for a given set of facilities and month" do
        facilities = create_list(:facility, 3, facility_group: facility_group)

        ck_this_month = described_class.new(facilities: facilities, for_end_of_month: Date.today.end_of_month).drug_consumption_cache_key
        ck_next_month = described_class.new(facilities: facilities, for_end_of_month: 1.month.from_now.end_of_month).drug_consumption_cache_key
        expect(ck_this_month).not_to eq(ck_next_month)

        facility = create(:facility, facility_group: facility_group)
        ck_this_month_with_facility = described_class.new(facilities: facilities << facility, for_end_of_month: Date.today.end_of_month).drug_consumption_cache_key
        expect(ck_this_month).not_to eq(ck_this_month_with_facility)
      end
    end
  end
end
