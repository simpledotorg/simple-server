require "rails_helper"

RSpec.describe DrugStockHelper, type: :helper do
  let(:drugs_by_category) do
    {
      "hypertension_arb" => [
        double("Losartan", id: "39695cff-7bc5-431b-a161-b736726e7ab9", name: "Losartan", dosage: "50 mg", rxnorm_code: "979467"),
        double("Telmisartan40", id: "487ac5f1-6fb5-4505-9494-2cfb3c1f2766", name: "Telmisartan", dosage: "40 mg", rxnorm_code: "316764")
      ],
      "hypertension_ccb" => [
        double("Amlodipine5", id: "404be899-bcf3-40e7-95cd-f8ce72a213a4", name: "Amlodipine", dosage: "5 mg", rxnorm_code: "329528")
      ]
    }
  end

  describe "#filter_params" do
    it "returns true if zone or size is present" do
      allow(helper).to receive(:params).and_return({zone: "summer gardens"})
      expect(helper.filter_params).to be true

      allow(helper).to receive(:params).and_return({size: "large"})
      expect(helper.filter_params).to be true
    end

    it "returns false if both zone and size are blank" do
      allow(helper).to receive(:params).and_return({})
      expect(helper.filter_params).to be false
    end
  end

  describe "#patient_count_for" do
    let(:report) { {district_patient_count: 7, facilities_total_patient_count: 10} }

    it "returns correct patient count based on filter_params" do
      allow(helper).to receive(:filter_params).and_return(false)
      expect(helper.patient_count_for(report)).to eq(7)

      allow(helper).to receive(:filter_params).and_return(true)
      expect(helper.patient_count_for(report)).to eq(10)
    end
  end

  describe "#drug_stock_for" do
    let(:report) do
      {
        total_drugs_in_stock: {"979467" => 5},
        drugs_in_stock_by_facility_id: {["1", "979467"] => 2, ["2", "979467"] => 3}
      }
    end
    let(:drug) { drugs_by_category["hypertension_arb"].first }

    it "returns correct drug stock based on filter_params" do
      allow(helper).to receive(:filter_params).and_return(false)
      expect(helper.drug_stock_for(report, drug)).to eq(5)

      allow(helper).to receive(:filter_params).and_return(true)
      expect(helper.drug_stock_for(report, drug)).to eq(5)
    end
  end

  describe "#aggregate_state_totals" do
    let(:districts) do
      {
        double("district") => {
          report: {
            total_drugs_in_stock: {"979467" => 10, "316764" => 0, "329528" => 5},
            total_patient_days: {"hypertension_arb" => {patient_days: 3}, "hypertension_ccb" => {patient_days: 1}},
            district_patient_count: 7
          }
        }
      }
    end

    it "aggregates totals, patient_days, and patient_count correctly" do
      result = helper.aggregate_state_totals(districts, drugs_by_category)
      expect(result).to eq(
        totals: {"979467" => 10, "316764" => 0, "329528" => 5},
        patient_days: {"hypertension_arb" => 3, "hypertension_ccb" => 1},
        patient_count: 7
      )
    end
  end

  describe "#state_aggregate" do
    let(:districts) do
      {
        double("district") => {
          report: {
            district_patient_count: 5,
            total_drug_consumption: {
              "hypertension_arb" => {drugs_by_category["hypertension_arb"].first => {consumed: 2}},
              "hypertension_ccb" => {base_doses: {total: 3}}
            }
          }
        }
      }
    end

    it "aggregates totals, base_totals, and patient_count correctly" do
      result = helper.state_aggregate(districts, drugs_by_category)
      expect(result[:patient_count]).to eq(5)
      expect(result[:totals].values.sum).to eq(2)
      expect(result[:base_totals]["hypertension_ccb"]).to eq(3)
    end
  end

  describe "#grouped_district_reports" do
    let(:district_reports) do
      [
        [double("district", state: "MP"), {}],
        [double("district", state: "Goa"), {}]
      ]
    end

    it "groups by state and sorts alphabetically" do
      result = helper.grouped_district_reports(district_reports)
      expect(result.map(&:first)).to eq(["Goa", "MP"])
    end
  end

  describe "#accessible_organization_facilities" do
    before { helper.instance_variable_set(:@accessible_facilities, [1]) }

    context "with slug present" do
      before { allow(helper).to receive(:drug_stock_tracking_slug).and_return("nhf") }

      it "returns true if slug included, false if not" do
        allow(Organization).to receive_message_chain(:joins, :where, :distinct, :pluck).and_return(["nhf"])
        expect(helper.accessible_organization_facilities).to eq(true)

        allow(Organization).to receive_message_chain(:joins, :where, :distinct, :pluck).and_return(["other"])
        expect(helper.accessible_organization_facilities).to eq(false)
      end
    end

    it "returns true if slug is nil" do
      allow(helper).to receive(:drug_stock_tracking_slug).and_return(nil)
      expect(helper.accessible_organization_facilities).to eq(true)
    end
  end

  describe "#facility_group_dropdown_title" do
    let(:group) { double("FacilityGroup", name: "Allahbad") }

    context "when can_view_all_districts_nav? is true" do
      before { allow(helper).to receive(:can_view_all_districts_nav?).and_return(true) }

      it "returns correct title based on overview and presence of group" do
        expect(helper.facility_group_dropdown_title(
          facility_group: group,
          overview: {facility_group: "all-districts"}
        )).to eq("All districts")

        expect(helper.facility_group_dropdown_title(
          facility_group: group,
          overview: {facility_group: "some-other"}
        )).to eq("Allahbad")

        expect(helper.facility_group_dropdown_title(
          facility_group: nil,
          overview: {facility_group: "some-other"}
        )).to eq("Select Districts")
      end
    end

    context "when can_view_all_districts_nav? is false" do
      before { allow(helper).to receive(:can_view_all_districts_nav?).and_return(false) }

      it "returns group name" do
        expect(helper.facility_group_dropdown_title(facility_group: group)).to eq("Allahbad")
      end
    end
  end

  describe "#aggregate_district_drug_stock" do
    let(:reports_to_aggregate) do
      {
        double("district") => {
          report: {
            district_patient_count: 10,
            facilities_total_patient_count: 10,
            total_drugs_in_stock: {"979467" => 5},
            drugs_in_stock_by_facility_id: {["1", "979467"] => 3},
            total_patient_days: {"hypertension_arb" => {patient_days: 4}}
          }
        }
      }
    end
    let(:first_drugs_by_category) { drugs_by_category }

    it "aggregates totals, patient_days, and patient_count correctly" do
      allow(helper).to receive(:filter_params).and_return(true)
      result = helper.aggregate_district_drug_stock(reports_to_aggregate, first_drugs_by_category)
      expect(result[:totals]["979467"]).to eq(3)
      expect(result[:patient_days]["hypertension_arb"]).to eq(4)
      expect(result[:patient_count]).to eq(10)
    end
  end

  describe "#aggregate_drug_consumption" do
    let(:district_reports) do
      {
        double("district") => {
          report: {
            district_patient_count: 6,
            total_drug_consumption: {
              "hypertension_arb" => {drugs_by_category["hypertension_arb"].first => {consumed: 2}},
              "hypertension_ccb" => {base_doses: {total: 3}}
            }
          }
        }
      }
    end

    it "aggregates totals, base_totals, and patient_count correctly" do
      result = helper.aggregate_drug_consumption(district_reports, drugs_by_category)
      expect(result[:patient_count]).to eq(6)
      expect(result[:totals].values.sum).to eq(2)
      expect(result[:base_totals]["hypertension_ccb"]).to eq(3)
    end
  end
end
