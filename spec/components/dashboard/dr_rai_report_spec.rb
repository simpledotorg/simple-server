require "rails_helper"

RSpec.describe Dashboard::DrRaiReport, type: :component do
  let(:quarter1) { Period.new(type: :quarter, value: "Q1-2024") }
  let(:quarter2) { Period.new(type: :quarter, value: "Q2-2024") }
  let(:district_with_facilities) { setup_district_with_facilities }
  let(:region) { district_with_facilities[:region].slug }
  let(:quarterlies) do
    {
      quarter1 => {},
      quarter2 => {}
    }
  end

  before do
    stub_request = ActionDispatch::TestRequest.create
    stub_request.path = "/reports/regions/block/#{region}"
    allow_any_instance_of(ActionView::Base).to receive(:request).and_return(stub_request)
  end

  around do |example|
    Timecop.freeze("June 25 2024 15:12 GMT") { example.run }
  end

  describe "#initialize" do
    it "defaults to current_period if selected_quarter is nil" do
      allow(Period).to receive(:current).and_return(quarter1)
      render_inline(described_class.new(quarterlies, region))

      component = page.find("#dr-rai--progress", match: :first)
      expect(component).to be_present
    end

    it "sets selected_period to the passed quarter" do
      render_inline(described_class.new(quarterlies, region, "Q2-2024"))
      expect(page).to have_text("Q2 2024")
    end
  end

  describe "#classes_for_period" do
    it "includes 'selected' when period matches selected_period" do
      comp = described_class.new(quarterlies, region, "Q1-2024")
      expect(comp.classes_for_period(quarter1).split).to include("selected")
    end

    it "does not include 'selected' when period does not match" do
      comp = described_class.new(quarterlies, region, "Q1-2024")
      expect(comp.classes_for_period(quarter2).split).not_to include("selected")
    end

    it "raises if argument is not a Period" do
      comp = described_class.new(quarterlies, region, "Q1-2024")
      expect { comp.classes_for_period("2024-Q1") }.to raise_error(/is not a Period/)
    end
  end

  describe "#start_of / #end_of" do
    let(:date_range_period) do
      instance_double("Period", begin: Date.new(2024, 1, 1), end: Date.new(2024, 3, 31))
    end

    it "formats the start date" do
      comp = described_class.new(quarterlies, region, "Q1-2024")
      expect(comp.start_of(comp.selected_period)).to eq("Jan-1")
    end

    it "formats the end date" do
      comp = described_class.new(quarterlies, region, "Q1-2024")
      expect(comp.end_of(comp.selected_period)).to eq("Mar-31")
    end
  end

  describe "#human_readable" do
    it "returns human readable string for a Period" do
      comp = described_class.new(quarterlies, region, "Q2-2024")
      expect(comp.human_readable(comp.selected_period)).to eq("Q2 2024")
    end
  end

  describe "stale periods" do
    it "does not allow adding new actions" do
      comp = described_class.new(quarterlies, region, "Q1-2024")
      the_page = render_inline(comp)
      add_action_button = the_page.css(".add-action-button")
      expect(add_action_button).to be_empty
    end
  end

  describe "current period" do
    it "allows new actions to be added" do
      comp = described_class.new(quarterlies, region, "Q2-2024")
      the_page = render_inline(comp)
      add_action_button = the_page.css(".add-action-button")
      expect(add_action_button).not_to be_empty
    end
  end
end
