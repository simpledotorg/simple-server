require "rails_helper"

RSpec.describe Reports::ProgressMonthlyFollowUpsComponent, type: :component do
  let(:region) { double("Region", name: "Region 1") }
  let(:diagnosis) { "Diabetes" }

  let(:period_info_data) do
    (6..11).each_with_object({}) do |month, hash|
      date = Date.new(2024, month, 1).beginning_of_month
      date_str = date.to_s
      ltfu_since_date = date.prev_month.end_of_month.strftime("%d-%b-%Y")
      name = date.strftime("%b-%Y")
      hash[date_str] = {name: name, ltfu_since_date: ltfu_since_date}
    end
  end

  let(:period_info) do
    period_info_data.map { |date_str, data| [Period.new(type: :month, value: date_str), data] }.to_h
  end

  let(:monthly_follow_ups_data) do
    {
      "2024-06-01" => 5,
      "2024-07-01" => 4,
      "2024-08-01" => 3,
      "2024-09-01" => 4,
      "2024-10-01" => 11,
      "2024-11-01" => 2
    }
  end

  let(:monthly_follow_ups) do
    monthly_follow_ups_data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  let(:rendered_component) do
    render_inline(described_class.new(
      monthly_follow_ups: monthly_follow_ups,
      period_info: period_info,
      region: region,
      diagnosis: diagnosis
    ))
  end

  describe "rendering the component" do
    it "renders the title correctly" do
      expect(rendered_component).to have_css("h2", text: I18n.t("progress_tab.diagnosis_report.monthly_follow_up_patients.title"))
    end

    it "renders the subtitle with correct facility name and diagnosis" do
      expect(rendered_component).to have_selector("p", text: I18n.t("progress_tab.diagnosis_report.monthly_follow_up_patients.subtitle", facility_name: region.name, diagnosis: diagnosis))
    end

    it "displays the correct number of total registrations" do
      monthly_follow_ups_data.values.each do |value|
        expect(rendered_component).to have_text(value.to_s)
      end
    end

    it "passes the correct data to the data bar graph partial" do
      expect(rendered_component).to have_selector('div[data-graph-type="bar-chart"]')
      monthly_follow_ups_data.keys.each do |date_str|
        expect(rendered_component).to have_text(period_info_data[date_str][:name])
      end
      monthly_follow_ups_data.values.each { |value| expect(rendered_component).to have_text(value.to_s) }
    end
  end

  describe "when diagnosis is not passed" do
    let(:component_without_diagnosis) do
      render_inline(described_class.new(
        monthly_follow_ups: monthly_follow_ups,
        period_info: period_info,
        region: region
      ))
    end

    it 'defaults to "Hypertension" as diagnosis' do
      expect(component_without_diagnosis).to have_selector("p", text: I18n.t("progress_tab.diagnosis_report.monthly_follow_up_patients.subtitle", facility_name: region.name, diagnosis: "Hypertension"))
    end
  end

  describe "handling empty data" do
    let(:empty_data) { {} }

    shared_examples "renders nothing if empty" do |data_key|
      it "renders nothing if #{data_key} is empty" do
        component_with_empty_data = render_inline(described_class.new(
          monthly_follow_ups: data_key == :monthly_follow_ups ? empty_data : monthly_follow_ups,
          period_info: data_key == :period_info ? empty_data : period_info,
          region: region,
          diagnosis: diagnosis
        ))
        expect(component_with_empty_data).to have_no_text(data_key.to_s)
      end
    end

    include_examples "renders nothing if empty", :monthly_follow_ups
    include_examples "renders nothing if empty", :period_info
  end
end
