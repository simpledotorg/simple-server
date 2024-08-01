require "rails_helper"

RSpec.describe MyFacilitiesHelper, type: :helper do
  describe "patient_days_css_class" do
    it "is nil if patient_days is nil" do
      expect(patient_days_css_class(nil)).to be_nil
    end

    it "returns red-new if < 30" do
      expect(patient_days_css_class(29)).to eq("bg-red")
    end

    it "is orange for 30 to < 60" do
      expect(patient_days_css_class(35)).to eq("bg-orange")
    end

    it "is yellow-dark for 60 to < 90" do
      expect(patient_days_css_class(66)).to eq("bg-yellow")
    end

    it "is green for more than 90" do
      expect(patient_days_css_class(91)).to eq("bg-green")
    end

    it "can change the prefix for the css class" do
      expect(patient_days_css_class(29, prefix: "c")).to eq("c-red")
      expect(patient_days_css_class(200, prefix: "c")).to eq("c-green")
    end
  end

  describe "#opd_load" do
    let!(:facility) { create(:facility, monthly_estimated_opd_load: 100) }

    it "returns nil if the selected period is not :month or :quarter" do
      expect(opd_load(facility, :day)).to be_nil
    end

    it "returns the monthly_estimated_opd_load if the selected_period is :month" do
      expect(opd_load(facility, :month)).to eq 100
    end

    it "returns the 3 * monthly_estimated_opd_load if the selected_period is :quarter" do
      expect(opd_load(facility, :quarter)).to eq 300
    end
  end

  describe "#add_special_drug" do
    let(:special_drug) { create(:protocol_drug, stock_tracked: false, name: "Rosuvastatin", dosage: "5 mg") }
    let(:region) { instance_double("Region") }
    let(:protocol) { instance_double("Protocol") }
    let(:source) { instance_double("Source", protocol: protocol) }
    let(:protocol_drugs) { [create(:protocol_drug, stock_tracked: true, name: "Some Drug")] }

    before do
      allow(region).to receive_message_chain(:source, :protocol, :protocol_drugs, :find_by).and_return(special_drug)
    end

    context "when CountryConfig name is Bangladesh" do
      before do
        allow(CountryConfig).to receive_message_chain(:current, :[]).with(:name).and_return("Bangladesh")
      end

      it "includes the special drug if it is not already in the list" do
        result = add_special_drug(protocol_drugs, region)
        expect(result).to include(special_drug)
      end

      it "does not add the special drug if it is already in the list" do
        protocol_drugs << special_drug
        result = add_special_drug(protocol_drugs, region)
        expect(result).to match_array(protocol_drugs)
      end
    end

    context "when CountryConfig name is not Bangladesh" do
      before do
        allow(CountryConfig).to receive_message_chain(:current, :[]).with(:name).and_return("India")
      end

      it "does not include the special drug in the list" do
        result = add_special_drug(protocol_drugs, region)
        expect(result).not_to include(special_drug)
      end
    end
  end
end
