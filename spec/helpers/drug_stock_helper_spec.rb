require "rails_helper"

RSpec.describe DrugStockHelper, type: :helper do
  let(:drugs_by_category) do
    {
      "hypertension_arb" => [
        double("ProtocolDrug", id: "39695cff-7bc5-431b-a161-b736726e7ab9", name: "Losartan", dosage: "50 mg", rxnorm_code: "979467"),
        double("ProtocolDrug", id: "487ac5f1-6fb5-4505-9494-2cfb3c1f2766", name: "Telmisartan", dosage: "40 mg", rxnorm_code: "316764"),
        double("ProtocolDrug", id: "49131b37-5384-4899-a195-28e79903cd3b", name: "Telmisartan", dosage: "80 mg", rxnorm_code: "316765")
      ],
      "hypertension_ccb" => [
        double("ProtocolDrug", id: "404be899-bcf3-40e7-95cd-f8ce72a213a4", name: "Amlodipine", dosage: "5 mg", rxnorm_code: "329528"),
        double("ProtocolDrug", id: "33d90c3f-8ad7-4f6b-ae17-c4af5f93ad41", name: "Amlodipine", dosage: "10 mg", rxnorm_code: "329526")
      ],
      "hypertension_diuretic" => [
        double("ProtocolDrug", id: "e18d9140-6392-41ef-83c2-acc327598008", name: "Chlorthalidone", dosage: "12.5 mg", rxnorm_code: "331132"),
        double("ProtocolDrug", id: "90ca7a13-b9db-423d-888f-82a2b6011c37", name: "Hydrochlorothiazide", dosage: "25 mg", rxnorm_code: "316049")
      ]
    }
  end

  describe "#state_aggregate" do
    let(:districts) do
      {
        double("district") => {report: {district_patient_count: 17, total_drug_consumption: {}}}
      }
    end

    it "aggregates totals, base_totals, and patient_count" do
      result = helper.state_aggregate(districts, drugs_by_category)
      expect(result).to eq(
        totals: {},
        base_totals: {},
        patient_count: 17
      )
    end
  end

  describe "#aggregate_state_totals" do
    let(:districts) do
      {
        double("district") => {
          report: {
            total_drugs_in_stock: {
              "979467" => 172,
              "316764" => 514,
              "316765" => 819,
              "329528" => 744,
              "329526" => 101,
              "331132" => 156,
              "316049" => 530
            },
            total_patient_days: {
              "hypertension_arb" => {patient_days: 369},
              "hypertension_ccb" => {patient_days: 39},
              "hypertension_diuretic" => {patient_days: 807}
            },
            district_patient_count: 17
          }
        }
      }
    end

    it "aggregates totals, patient_days, and patient_count using real data shape" do
      result = helper.aggregate_state_totals(districts, drugs_by_category)
      expect(result).to eq(
        totals: {
          "979467" => 172,
          "316764" => 514,
          "316765" => 819,
          "329528" => 744,
          "329526" => 101,
          "331132" => 156,
          "316049" => 530
        },
        patient_days: {
          "hypertension_arb" => 369,
          "hypertension_ccb" => 39,
          "hypertension_diuretic" => 807
        },
        patient_count: 17
      )
    end
  end

  describe "#grouped_district_reports" do
    let(:district_reports) do
      [
        [double("district", state: "Haryana"), {}],
        [double("district", state: "Maharashtra"), {}]
      ]
    end

    it "groups by state and sorts" do
      result = helper.grouped_district_reports(district_reports)
      expect(result.map(&:first)).to eq(["Haryana", "Maharashtra"])
    end
  end

  describe "#accessible_organization_facilities" do
    before { helper.instance_variable_set(:@accessible_facilities, [1, 2, 3]) }

    let(:slug) { "nhf" }
    before { allow(helper).to receive(:drug_stock_tracking_slug).and_return(slug) }

    context "when drug_stock_tracking_slug is present" do
      it "returns true if organization slugs include the tracking slug" do
        allow(Organization).to receive_message_chain(:joins, :where, :distinct, :pluck).and_return([slug])
        expect(helper.accessible_organization_facilities).to eq(true)
      end

      it "returns false if organization slugs do not include the tracking slug" do
        allow(Organization).to receive_message_chain(:joins, :where, :distinct, :pluck).and_return(["some_other_slug"])
        expect(helper.accessible_organization_facilities).to eq(false)
      end
    end

    context "when drug_stock_tracking_slug is nil" do
      let(:slug) { nil }

      it "returns true" do
        expect(helper.accessible_organization_facilities).to eq(true)
      end
    end
  end

  describe "#facility_group_dropdown_title" do
    let(:sangli_group) { double("FacilityGroup", name: "Sangli") }
    let(:allahbad_group) { double("FacilityGroup", name: "Allahbad") }

    context "when can_view_all_districts_nav? is true" do
      before { allow(helper).to receive(:can_view_all_districts_nav?).and_return(true) }

      it "returns 'All districts' if overview is true" do
        expect(helper.facility_group_dropdown_title(facility_group: sangli_group, overview: true)).to eq("All districts")
      end

      it "returns facility_group name if overview is false" do
        expect(helper.facility_group_dropdown_title(facility_group: sangli_group, overview: false)).to eq("Sangli")
        expect(helper.facility_group_dropdown_title(facility_group: allahbad_group, overview: false)).to eq("Allahbad")
      end

      it "returns 'Select Districts' if facility_group is nil and overview is false" do
        expect(helper.facility_group_dropdown_title(facility_group: nil, overview: false)).to eq("Select Districts")
      end
    end

    context "when can_view_all_districts_nav? is false" do
      before { allow(helper).to receive(:can_view_all_districts_nav?).and_return(false) }

      it "returns facility_group name if present" do
        expect(helper.facility_group_dropdown_title(facility_group: sangli_group)).to eq("Sangli")
      end
    end
  end
end
