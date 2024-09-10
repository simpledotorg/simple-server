require "rails_helper"

describe Dashboard::Diabetes::BsOver200GraphComponent, type: :component do
  let(:range) { Range.new(Period.month(2.months.ago), Period.current) }
  let(:repo) { Reports::Repository.new(region, periods: range) }
  let(:presenter) { Reports::RepositoryPresenter.new(repo) }
  let(:distict_with_facilities) { setup_district_with_facilities }
  let(:region) { distict_with_facilities[:region] }
  let(:facility_1) { distict_with_facilities[:facility_1] }
  let(:region_data) { presenter.call(region) }
  let(:use_who_standard) { false }
  let(:bs_over200_graph_component) {
    described_class.new(
      region: region,
      data: region_data,
      period: Period.current,
      use_who_standard: use_who_standard
    )
  }

  it "has the required labels" do
    render_inline(bs_over200_graph_component)
    expect(page.find(:css, "h3").text.strip).to eq("Blood sugar 200-299 or ≥300")
    expect(page.find("#bsOver200PatientsTrend").find(:xpath, "div/p").text.strip).to eq("Diabetes patients in Test District with blood sugar 200-299 or blood sugar ≥300 at their last visit in the last 3 months")
    expect(Capybara.string(page.find("#bsOver200PatientsTrend i")[:title]).all("p")[0].text).to eq("Blood sugar 200-299 numerator: Patients with RBS/PPBS 200-299, FBS 126-199, or HbA1c 7.0-8.9 at their last visit in the last 3 months")
    expect(Capybara.string(page.find("#bsOver200PatientsTrend i")[:title]).all("p")[1].text).to eq("Blood sugar ≥300 numerator: Patients with RBS/PPBS ≥300, FBS ≥200, or HbA1c ≥9.0 at their last visit in the last 3 months")
    expect(page.find("#bsOver200PatientsTrend").find(:xpath, "div/div[2]/div/p[1]").text).to match(/patients with a blood sugar ≥300 from/)
    expect(page.find("#bsOver200PatientsTrend").find(:xpath, "div/div[3]/div/p[1]").text).to match(/patients with a blood sugar 200-299 from/)
  end

  context "with the feature flag for global diabetes indicator enabled" do
    let(:use_who_standard) { true }

    it "has the updated labels" do
      render_inline(bs_over200_graph_component)
      expect(page.find(:css, "h3").text.strip).to eq("Blood sugar 126-199 or ≥200")
      expect(page.find("#bsOver200PatientsTrend").find(:xpath, "div/p").text.strip).to eq("Diabetes patients in Test District with blood sugar 126-199mg/dl or blood sugar ≥200mg/dl at their last visit in the last 3 months")
      expect(Capybara.string(page.find("#bsOver200PatientsTrend i")[:title]).all("p")[0].text).to eq("Blood sugar 126-199 numerator: Patients with FBS 126-199, or HBA1C 7.0%-8.9% at their last visit in the last 3 months")
      expect(Capybara.string(page.find("#bsOver200PatientsTrend i")[:title]).all("p")[1].text).to eq("Blood sugar ≥200 numerator: Patients with FBS ≥200, or HBA1C ≥9.0% at their last visit in the last 3 months")
      expect(page.find("#bsOver200PatientsTrend").find(:xpath, "div/div[2]/div/p[1]").text).to match(/patients with a blood sugar ≥200 from/)
      expect(page.find("#bsOver200PatientsTrend").find(:xpath, "div/div[3]/div/p[1]").text).to match(/patients with a blood sugar 126-199 from/)
    end
  end
end
