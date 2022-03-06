require "rails_helper"

RSpec.describe MyFacilitiesHelper, type: :helper do
  describe "patient_days_css_class" do
    it "is nil if patient_days is nil" do
      expect(patient_days_css_class(nil)).to be_nil
    end

    it "returns red-new if < 30" do
      expect(patient_days_css_class(29)).to eq("bgc-red-new")
    end

    it "is orange-new for 30 to < 60" do
      expect(patient_days_css_class(35)).to eq("bgc-orange-new")
    end

    it "is yellow-dark-new for 60 to < 90" do
      expect(patient_days_css_class(66)).to eq("bgc-yellow-dark-new")
    end

    it "is green-new for more than 90" do
      expect(patient_days_css_class(91)).to eq("bgc-green-new")
    end

    it "can change the prefix for the css class" do
      expect(patient_days_css_class(29, prefix: "c")).to eq("c-red-new")
      expect(patient_days_css_class(200, prefix: "c")).to eq("c-green-new")
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
end
