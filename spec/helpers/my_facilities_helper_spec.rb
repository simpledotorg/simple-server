require "rails_helper"

RSpec.describe MyFacilitiesHelper, type: :helper do
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
