require "rails_helper"

RSpec.describe "reports/regions/_diabetes_footnotes.html.erb", type: :view do
  let(:distict_with_facilities) { setup_district_with_facilities }
  let(:region) { distict_with_facilities[:region] }

  it "has the correct labels" do
    assign(:region, region)
    render
    all_texts = Capybara.string(rendered).all("p")
    expect(all_texts[8].text.strip).to eq("Blood sugar < 200")
    expect(all_texts[9].text.strip).to eq("Numerator: Patients with RBS/PPBS <200, FBS <126, or HbA1c <7.0 at their last visit in the last 3 months")
    expect(all_texts[11].text.strip).to eq("Blood Sugar 200-299")
    expect(all_texts[12].text.strip).to eq("Numerator: Patients with RBS/PPBS 200-299, FBS 126-199, or HbA1c 7.0-8.9 at their last visit in the last 3 months")
    expect(all_texts[14].text.strip).to eq("Blood sugar ≥300")
    expect(all_texts[15].text.strip).to eq("Numerator: Patients with RBS/PPBS ≥300, FBS ≥200, or HbA1c ≥9.0 at their last visit in the last 3 months")
  end

  context "with the feature flag for global diabetes indicator enabled" do
    before do
      Flipper.enable(:diabetes_who_standard_indicator)
    end

    it "has the updated labels" do
      assign(:region, region)
      render
      all_texts = Capybara.string(rendered).all("p")
      expect(all_texts[8].text.strip).to eq("Blood sugar < 126")
      expect(all_texts[9].text.strip).to eq("Numerator: Patients with FBS <126, or HbA1c <7.0 at their last visit in the last 3 months")
      expect(all_texts[11].text.strip).to eq("Blood Sugar 126-199")
      expect(all_texts[12].text.strip).to eq("Numerator: Patients with FBS 126-199, or HbA1c 7.0-8.9 at their last visit in the last 3 months")
      expect(all_texts[14].text.strip).to eq("Blood sugar ≥200")
      expect(all_texts[15].text.strip).to eq("Numerator: Patients with FBS ≥200, or HbA1c ≥9.0 at their last visit in the last 3 months")
    end
  end
end
