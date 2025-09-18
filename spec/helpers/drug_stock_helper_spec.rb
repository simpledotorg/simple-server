require "rails_helper"

RSpec.describe DrugStockHelper, type: :helper do
  let(:facility) { double("Facility", id: 1, facility_group_id: 10) }
  let(:accessible_facilities) { [facility] }

  before do
    allow(facility).to receive(:facility_group_id).and_return(10)
    allow(accessible_facilities).to receive(:pluck).with(:facility_group_id).and_return([10])
    helper.instance_variable_set(:@accessible_facilities, accessible_facilities)
  end

  describe "#drug_stock_region_label" do
    it "returns 'District warehouse' for district_region" do
      region = double("Region", district_region?: true, localized_region_type: "district")
      expect(helper.drug_stock_region_label(region)).to eq("District warehouse")
    end

    it "returns capitalized type for non-district_region" do
      region = double("Region", district_region?: false, localized_region_type: "state")
      expect(helper.drug_stock_region_label(region)).to eq("State")
    end
  end

  describe "#filter_params" do
    it "returns true if zone param is present" do
      allow(helper).to receive(:params).and_return({zone: "summer gardens"})
      expect(helper.filter_params).to eq(true)
    end

    it "returns true if size param is present" do
      allow(helper).to receive(:params).and_return({size: "large"})
      expect(helper.filter_params).to eq(true)
    end

    it "returns false if neither param is present" do
      allow(helper).to receive(:params).and_return({})
      expect(helper.filter_params).to eq(false)
    end
  end

  describe "#patient_count_for" do
    let(:report) { {facilities_total_patient_count: 10, district_patient_count: 5} }

    it "returns facilities_total_patient_count when filter_params true" do
      allow(helper).to receive(:filter_params).and_return(true)
      expect(helper.patient_count_for(report)).to eq(10)
    end

    it "returns district_patient_count when filter_params false" do
      allow(helper).to receive(:filter_params).and_return(false)
      expect(helper.patient_count_for(report)).to eq(5)
    end
  end

  describe "#drug_stock_for" do
    let(:drug) { double("Drug", rxnorm_code: "D123") }
    let(:report) do
      {
        drugs_in_stock_by_facility_id: {[1, "D123"] => 5, [2, "D123"] => 3},
        total_drugs_in_stock: {"D123" => 10}
      }
    end

    it "sums drugs_in_stock_by_facility_id when filter_params true" do
      allow(helper).to receive(:filter_params).and_return(true)
      expect(helper.drug_stock_for(report, drug)).to eq(8)
    end

    it "returns total_drugs_in_stock when filter_params false" do
      allow(helper).to receive(:filter_params).and_return(false)
      expect(helper.drug_stock_for(report, drug)).to eq(10)
    end
  end

  describe "#aggregate_state_totals" do
    let(:drug) { double("Drug", rxnorm_code: "D123") }
    let(:report) do
      {facilities_total_patient_count: 10, district_patient_count: 5,
       total_patient_days: {hypertension: {patient_days: 20}},
       total_drugs_in_stock: {"D123" => 15}}
    end
    let(:districts) { {district1: {report: report}} }
    let(:drugs_by_category) { {hypertension: [drug]} }

    it "aggregates totals, patient_days, and patient_count" do
      allow(helper).to receive(:filter_params).and_return(false)
      result = helper.aggregate_state_totals(districts, drugs_by_category)
      expect(result[:totals]["D123"]).to eq(15)
      expect(result[:patient_days][:hypertension]).to eq(20)
      expect(result[:patient_count]).to eq(5)
    end
  end

  describe "#grouped_district_reports" do
    it "groups districts by state and sorts by state" do
      district1 = double("District", state: "B")
      district2 = double("District", state: "A")
      reports = {district1 => {}, district2 => {}}
      grouped = helper.grouped_district_reports(reports)
      expect(grouped.map(&:first)).to eq(["A", "B"])
    end
  end

  describe "#state_aggregate" do
    let(:drug1) { double("Drug", id: 1) }
    let(:drug2) { double("Drug", id: 2) }
    let(:report) do
      {
        district_patient_count: 5,
        total_drug_consumption: {
          hypertension: {drug1 => {consumed: 3}, drug2 => {consumed: "error"}, :base_doses => {total: 10}}
        }
      }
    end
    let(:districts) { {d1: {report: report}} }
    let(:drugs_by_category) { {hypertension: [drug1, drug2]} }

    it "calculates totals, base_totals and patient_count ignoring 'error'" do
      result = helper.state_aggregate(districts, drugs_by_category)
      expect(result[:totals][1]).to eq(3)
      expect(result[:totals][2]).to eq(0)
      expect(result[:base_totals][:hypertension]).to eq(10)
      expect(result[:patient_count]).to eq(5)
    end
  end

  describe "#accessible_organization_districts" do
    let(:accessible_facilities_relation) { double("Relation") }

    before do
      helper.instance_variable_set(:@accessible_facilities, accessible_facilities_relation)
      allow(accessible_facilities_relation).to receive(:pluck).with(:facility_group_id).and_return([10])
    end

    context "slug present" do
      before { allow(helper).to receive(:drug_stock_tracking_slug).and_return("nhf") }

      it "queries FacilityGroups with organization join" do
        expect(FacilityGroup).to receive(:includes).with(:facilities).and_call_original
        helper.accessible_organization_districts
      end
    end

    context "slug nil" do
      before { allow(helper).to receive(:drug_stock_tracking_slug).and_return(nil) }

      it "returns FacilityGroups without organization join" do
        expect(FacilityGroup).to receive(:where).with(id: [10]).and_call_original
        helper.accessible_organization_districts
      end
    end
  end

  describe "#accessible_organization_districts" do
    let(:fg) { double("FacilityGroup") }

    context "slug present" do
      before { allow(helper).to receive(:drug_stock_tracking_slug).and_return("nhf") }
      it "queries FacilityGroups with organization join" do
        expect(FacilityGroup).to receive(:includes).with(:facilities).and_call_original
        # Full DB test not possible in helper spec; we ensure method runs
        helper.accessible_organization_districts
      end
    end

    context "slug nil" do
      before { allow(helper).to receive(:drug_stock_tracking_slug).and_return(nil) }
      it "returns FacilityGroups without organization join" do
        expect(FacilityGroup).to receive(:where).and_call_original
        helper.accessible_organization_districts
      end
    end
  end

  describe "#facility_group_dropdown_title" do
    let(:fg) { double("FacilityGroup", name: "Test FG") }

    it "returns overview title when can_view_all_districts_nav? true and overview true" do
      allow(helper).to receive(:can_view_all_districts_nav?).and_return(true)
      expect(helper.facility_group_dropdown_title(facility_group: fg, overview: true)).to eq("All districts")
    end

    it "returns facility group name when overview false" do
      allow(helper).to receive(:can_view_all_districts_nav?).and_return(true)
      expect(helper.facility_group_dropdown_title(facility_group: fg, overview: false)).to eq("Test FG")
    end

    it "returns facility group name when cannot view all districts" do
      allow(helper).to receive(:can_view_all_districts_nav?).and_return(false)
      expect(helper.facility_group_dropdown_title(facility_group: fg)).to eq("Test FG")
    end
  end

  describe "#aggregate_district_drug_stock" do
    let(:drug) { double("Drug", rxnorm_code: "D123") }
    let(:report) do
      {
        facilities_total_patient_count: 10,
        district_patient_count: 5,
        drugs_in_stock_by_facility_id: {[1, "D123"] => 3},
        total_drugs_in_stock: {"D123" => 5},
        total_patient_days: {hypertension: {patient_days: 7}}
      }
    end
    let(:district_reports) { {d1: {report: report}} }
    let(:drugs_by_category) { {hypertension: [drug]} }

    it "aggregates totals, patient_days, and patient_count with filter_params true" do
      allow(helper).to receive(:filter_params).and_return(true)
      result = helper.aggregate_district_drug_stock(district_reports, drugs_by_category)
      expect(result[:totals]["D123"]).to eq(3)
      expect(result[:patient_days][:hypertension]).to eq(7)
      expect(result[:patient_count]).to eq(10)
    end

    it "aggregates totals, patient_days, and patient_count with filter_params false" do
      allow(helper).to receive(:filter_params).and_return(false)
      result = helper.aggregate_district_drug_stock(district_reports, drugs_by_category)
      expect(result[:totals]["D123"]).to eq(5)
      expect(result[:patient_days][:hypertension]).to eq(7)
      expect(result[:patient_count]).to eq(5)
    end
  end

  describe "#aggregate_drug_consumption" do
    let(:drug1) { double("Drug", id: 1) }
    let(:drug2) { double("Drug", id: 2) }
    let(:report) do
      {
        district_patient_count: 5,
        total_drug_consumption: {
          hypertension: {
            drug1 => {consumed: 3},
            drug2 => {consumed: "error"},
            :base_doses => {total: 10}
          }
        }
      }
    end
    let(:district_reports) { {d1: {report: report}} }
    let(:drugs_by_category) { {hypertension: [drug1, drug2]} }

    it "calculates totals, base_totals and patient_count ignoring 'error'" do
      result = helper.aggregate_drug_consumption(district_reports, drugs_by_category)
      expect(result[:totals][1]).to eq(3)
      expect(result[:totals][2]).to eq(0)
      expect(result[:base_totals][:hypertension]).to eq(10)
      expect(result[:patient_count]).to eq(5)
    end
  end
end
