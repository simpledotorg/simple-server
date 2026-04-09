# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProgressTab::BreakdownTableComponent, type: :component do
  let(:title) { "Hypertension" }
  let(:breakdown) do
    {
      all: 100,
      male: 40,
      female: 55,
      transgender: 5
    }
  end

  def render_component(title: self.title, breakdown: self.breakdown)
    render_inline(described_class.new(title: title, breakdown: breakdown))
  end

  describe "gender rows rendering" do
    context "when country config supports all genders (male, female, transgender)" do
      before do
        allow(CountryConfig).to receive(:supported_genders).and_return(%w[male female transgender])
      end

      it "renders all three gender rows" do
        render_component

        expect(page).to have_text(I18n.t("progress_tab.genders.male"))
        expect(page).to have_text(I18n.t("progress_tab.genders.female"))
        expect(page).to have_text(I18n.t("progress_tab.genders.transgender"))
      end

      it "renders the correct counts for each gender" do
        render_component

        expect(page).to have_text("40")
        expect(page).to have_text("55")
        expect(page).to have_text("5")
      end

      it "renders the total count" do
        render_component

        expect(page).to have_text("100")
      end
    end

    context "when country config supports only male and female (e.g., Ethiopia)" do
      before do
        allow(CountryConfig).to receive(:supported_genders).and_return(%w[male female])
      end

      it "renders only male and female gender rows" do
        render_component

        expect(page).to have_text(I18n.t("progress_tab.genders.male"))
        expect(page).to have_text(I18n.t("progress_tab.genders.female"))
        expect(page).not_to have_text(I18n.t("progress_tab.genders.transgender"))
      end

      it "renders the correct counts for male and female" do
        render_component

        expect(page).to have_text("40")
        expect(page).to have_text("55")
      end

      it "does not render transgender count" do
        render_component

        # The transgender count (5) should not appear as a standalone gender row
        # but 5 might appear in other contexts, so we check for the label
        expect(page).not_to have_text(I18n.t("progress_tab.genders.transgender"))
      end
    end
  end

  describe "title rendering" do
    it "renders the title" do
      render_component

      expect(page).to have_selector("h3", text: title)
    end
  end

  describe "#include_bottom_border" do
    context "when title is 'Hypertension and diabetes'" do
      let(:title) { I18n.t("progress_tab.diagnoses.hypertension_and_diabetes") }

      it "does not include bottom border on the last gender row" do
        allow(CountryConfig).to receive(:supported_genders).and_return(%w[male female])
        render_component

        # The last row should not have bottom border classes when it's hypertension_and_diabetes
        last_gender_row = page.all("div.d-flex.ai-center.jc-space-between").last
        expect(last_gender_row[:class]).not_to include("bb-grey-mid")
      end
    end

    context "when title is not 'Hypertension and diabetes'" do
      let(:title) { "Hypertension" }

      it "includes bottom border on the last gender row" do
        allow(CountryConfig).to receive(:supported_genders).and_return(%w[male female])
        render_component

        # All rows should have bottom border when it's not hypertension_and_diabetes
        gender_rows = page.all("div.d-flex.ai-center.jc-space-between.mb-4px")
        gender_rows.each do |row|
          expect(row[:class]).to include("bb-grey-mid")
        end
      end
    end
  end

  describe "integration with actual CountryConfig" do
    it "uses the actual supported_genders from CountryConfig" do
      # This test ensures the component correctly integrates with CountryConfig
      # without mocking, using whatever country is configured in the test environment
      render_component

      CountryConfig.supported_genders.each do |gender|
        expect(page).to have_text(I18n.t("progress_tab.genders.#{gender}"))
      end
    end
  end
end
