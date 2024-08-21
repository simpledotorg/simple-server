require "rails_helper"

describe Dashboard::Diabetes::BsBelow200GraphComponent, type: :component do
  let(:range) { Range.new(Period.month(2.months.ago), Period.current) }
  let(:repo) { Reports::Repository.new(region, periods: range) }
  let(:presenter) { Reports::RepositoryPresenter.new(repo) }
  let(:distict_with_facilities) { setup_district_with_facilities }
  let(:region) { distict_with_facilities[:region] }
  let(:facility_1) { distict_with_facilities[:facility_1] }
  let(:region_data) { presenter.call(region) }
  let(:bs_below200_graph_component) {
    described_class.new(
      region: region,
      data: region_data,
      period: Period.current
    )
  }

  it "has the required labels" do
    render_inline(bs_below200_graph_component)
    expect(page.find(:css, "h3").text.strip).to eq("Blood sugar < 200")
    expect(page.find("#bsBelow200PatientsTrend").find(:xpath, "div/p").text.strip).to eq("Diabetes patients in Test District with blood sugar <200 at their last visit in the last 3 months")
    expect(Capybara.string(page.find("#bsBelow200PatientsTrend i")[:title]).first("p").text).to eq("Numerator: Patients with RBS/PPBS <200, FBS <126, or HbA1c <7.0 at their last visit in the last 3 months")
    expect(page.find("#bsBelow200PatientsTrend").find(:xpath, "div/div[2]/div/p[1]").text).to match(/patients with a blood sugar <200 from/)
  end

  context "with the feature flag for global diabetes indicator enabled" do
    before do
      Flipper.enable(:diabetes_who_standard_indicator)
    end

    it "has the updated labels" do
      render_inline(bs_below200_graph_component)
      expect(page.find(:css, "h3").text.strip).to eq("Blood sugar < 126")
      expect(page.find("#bsBelow200PatientsTrend").find(:xpath, "div/p").text.strip).to eq("Diabetes patients in Test District with blood sugar <126 or HbA1c <7 at their last visit in the last 3 months")
      expect(Capybara.string(page.find("#bsBelow200PatientsTrend i")[:title]).first("p").text).to eq("Numerator: Patients with FBS <126, or HbA1c <7.0 at their last visit in the last 3 months")
      expect(page.find("#bsBelow200PatientsTrend").find(:xpath, "div/div[2]/div/p[1]").text).to match(/patients with a blood sugar <126 from/)
    end
  end
end
