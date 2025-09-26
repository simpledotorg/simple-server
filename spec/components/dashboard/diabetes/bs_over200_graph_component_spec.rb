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
    expect(page.find(:css, "h3").text.strip).to eq("Blood sugar ≥200")
    expect(page.find("#bsOver200PatientsTrend").find(:xpath, "div/p[1]").text.strip).to eq("Diabetes patients in Test District with blood sugar 200-299 or blood sugar ≥300 at their last visit in the last 3 months")
    expect(Capybara.string(page.find("#bsOver200PatientsTrend i")[:title]).all("p")[0].text).to eq("Blood sugar 200-299 numerator: Patients with RBS/PPBS 200-299, FBS 126-199, or HbA1c 7.0-8.9 at their last visit in the last 3 months")
    expect(Capybara.string(page.find("#bsOver200PatientsTrend i")[:title]).all("p")[1].text).to eq("Blood sugar ≥300 numerator: Patients with RBS/PPBS ≥300, FBS ≥200, or HbA1c ≥9.0 at their last visit in the last 3 months")
    expect(page.find("#bsOver200PatientsTrend").find(:xpath, "div/div[2]/div/p[1]").text).to match(/patients with a blood sugar ≥300 from/)
    expect(page.find("#bsOver200PatientsTrend").find(:xpath, "div/div[3]/div/p[1]").text).to match(/patients with a blood sugar 200-299 from/)
    expect(page.find("#bsOver200PatientsTrend").find(:xpath, "div/p[2]").text.strip).to eq("of \n        patients registered till")
  end

  context "with the feature flag for global diabetes indicator enabled" do
    let(:use_who_standard) { true }

    it "has the updated labels" do
      render_inline(bs_over200_graph_component)
      expect(page.find(:css, "h3").text.strip).to eq("Blood sugar ≥126")
      expect(page.find("#bsOver200PatientsTrend").find(:xpath, "div/p[1]").text.strip).to eq("Diabetes patients in Test District with FBS ≥126mg/dL or HbA1c ≥7% at their last visit in the last 3 months")
      expect(Capybara.string(page.find("#bsOver200PatientsTrend i")[:title]).all("p")[0].text).to eq("Blood sugar 126-199 numerator: Patients with FBS 126-199mg/dL, or HbA1c 7%-8.9% at their last visit in the last 3 months")
      expect(Capybara.string(page.find("#bsOver200PatientsTrend i")[:title]).all("p")[1].text).to eq("Blood sugar ≥200 numerator: Patients with FBS ≥200mg/dL, or HbA1c ≥9% at their last visit in the last 3 months")
      expect(page.find("#bsOver200PatientsTrend").find(:xpath, "div/div[2]/div/p[1]").text).to match(/patients with FBS ≥200mg\/dL or HbA1c ≥9% from/)
      expect(page.find("#bsOver200PatientsTrend").find(:xpath, "div/div[3]/div/p[1]").text).to match(/patients with FBS 126-199mg\/dL or HbA1c 7%-8.9% from/)
      expect(page.find("#bsOver200PatientsTrend").find(:xpath, "div/p[2]").text.strip).to eq("of \n        patients registered till")
    end
  end
end
