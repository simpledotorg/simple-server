require "rails_helper"

RSpec.describe Dashboard::DrRaiReport, type: :component do
  let(:q1_2024) { "Q1-2024" }
  let(:q2_2024) { "Q2-2024" }
  let(:quarter1) { Period.new(type: :quarter, value: q1_2024) }
  let(:quarter2) { Period.new(type: :quarter, value: q2_2024) }
  let(:district_with_facilities) { setup_district_with_facilities }
  let(:region) { district_with_facilities[:region].slug }
  let(:periods) { [quarter1, quarter2] }
  let(:default_options) do
    {
      selected_quarter: nil,
      with_non_contactable: nil
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
      render_inline(described_class.new(periods, region, default_options))

      component = page.find("#dr-rai--progress", match: :first)
      expect(component).to be_present
    end

    it "sets selected_period to the passed quarter" do
      rai_options = default_options.merge(selected_quarter: q2_2024)
      render_inline(described_class.new(periods, region, rai_options))
      expect(page).to have_text("Q2 2024")
    end

    it "handles nil options without error and defaults to the current period" do
      allow(Period).to receive(:current).and_return(quarter1)
      expect {
        render_inline(described_class.new(periods, region, nil))
      }.not_to raise_error
      expect(page).to have_text("Q1 2024")
    end
  end

  describe "#classes_for_period" do
    it "includes 'selected' when period matches selected_period" do
      rai_options = default_options.merge(selected_quarter: q1_2024)
      comp = described_class.new(periods, region, rai_options)
      expect(comp.classes_for_period(quarter1).split).to include("selected")
    end

    it "does not include 'selected' when period does not match" do
      rai_options = default_options.merge(selected_quarter: q1_2024)
      comp = described_class.new(periods, region, rai_options)
      expect(comp.classes_for_period(quarter2).split).not_to include("selected")
    end

    it "raises if argument is not a Period" do
      rai_options = default_options.merge(selected_quarter: q1_2024)
      comp = described_class.new(periods, region, rai_options)
      expect { comp.classes_for_period("2024-Q1") }.to raise_error(/is not a Period/)
    end
  end

  describe "#start_of / #end_of" do
    let(:date_range_period) do
      instance_double("Period", begin: Date.new(2024, 1, 1), end: Date.new(2024, 3, 31))
    end

    it "formats the start date" do
      rai_options = default_options.merge(selected_quarter: q1_2024)
      comp = described_class.new(periods, region, rai_options)
      expect(comp.start_of(comp.selected_period)).to eq("Jan-1")
    end

    it "formats the end date" do
      rai_options = default_options.merge(selected_quarter: q1_2024)
      comp = described_class.new(periods, region, rai_options)
      expect(comp.end_of(comp.selected_period)).to eq("Mar-31")
    end
  end

  describe "#human_readable" do
    it "returns human readable string for a Period" do
      rai_options = default_options.merge(selected_quarter: q2_2024)
      comp = described_class.new(periods, region, rai_options)
      expect(comp.human_readable(comp.selected_period)).to eq("Q2 2024")
    end
  end

  describe "#action_plans_editable?" do
    it "is true on the last day of the current quarter's first month" do
      Timecop.freeze(Time.zone.parse("April 30 2024 15:12")) do
        component = described_class.new(periods, region, default_options.merge(selected_quarter: q2_2024))

        expect(component.action_plans_editable?).to be(true)
      end
    end

    it "is true on the first day of the current quarter's second month" do
      Timecop.freeze(Time.zone.parse("May 1 2024 15:12")) do
        component = described_class.new(periods, region, default_options.merge(selected_quarter: q2_2024))

        expect(component.action_plans_editable?).to be(true)
      end
    end

    it "is false on the first day of the current quarter's last month" do
      Timecop.freeze(Time.zone.parse("June 1 2024 15:12")) do
        component = described_class.new(periods, region, default_options.merge(selected_quarter: q2_2024))

        expect(component.action_plans_editable?).to be(false)
      end
    end

    it "is false when another quarter is selected" do
      Timecop.freeze(Time.zone.parse("April 15 2024 15:12")) do
        component = described_class.new(periods, region, default_options.merge(selected_quarter: q1_2024))

        expect(component.action_plans_editable?).to be(false)
      end
    end
  end

  describe "editing action plans" do
    let(:indicator) { create(:indicator, :contact_overdue_patients) }
    let(:action_plan) do
      create(
        :action_plan,
        region: Region.find_by!(slug: region),
        statement: "Call 20 overdue patients",
        actions: "Call patients marked \"high-risk\" & follow up",
        dr_rai_indicator: indicator,
        dr_rai_target: create(:target, :percentage, period: q2_2024, indicator: indicator)
      )
    end

    it "renders eligible action plans with safely escaped edit data" do
      Timecop.freeze(Time.zone.parse("April 15 2024 15:12")) do
        action_plan

        render_inline(described_class.new(periods, region, default_options.merge(selected_quarter: q2_2024)))

        edit_control = page.find(".edit-action-plan")
        expect(edit_control["data-action-plan-id"]).to eq(action_plan.id.to_s)
        expect(edit_control["data-target"]).to eq("#dr-rai--edit-sidebar")
        expect(edit_control["data-indicator"]).to eq("Contact overdue patients")
        expect(edit_control["data-target-statement"]).to eq("Call 20 overdue patients")
        expect(edit_control["data-actions"]).to eq("Call patients marked \"high-risk\" & follow up")
        expect(edit_control["data-target-statement"]).not_to include("&quot;")
        expect(edit_control["data-actions"]).not_to include("&amp;")
      end
    end

    it "preserves strings that jQuery data attributes would coerce" do
      Timecop.freeze(Time.zone.parse("April 15 2024 15:12")) do
        action_plan.update!(statement: "null", actions: "{\"enabled\":true}")

        render_inline(described_class.new(periods, region, default_options.merge(selected_quarter: q2_2024)))

        edit_control = page.find(".edit-action-plan")
        expect(edit_control["data-target-statement"]).to eq("null")
        expect(edit_control["data-actions"]).to eq("{\"enabled\":true}")
        expect(page.native.to_html).to include("editControl.attr('data-indicator')")
        expect(page.native.to_html).to include("editControl.attr('data-target-statement')")
        expect(page.native.to_html).to include("editControl.attr('data-actions')")
      end
    end

    it "renders a dedicated edit side panel congruent with the creation panel" do
      Timecop.freeze(Time.zone.parse("April 15 2024 15:12")) do
        action_plan

        render_inline(described_class.new(periods, region, default_options.merge(selected_quarter: q2_2024)))

        panel = page.find("#dr-rai--edit-sidebar.sidepanel.bs-canvas.bs-canvas-right.bs-canvas-anim")
        expect(panel).to have_css(".header", text: "Edit action")
        expect(panel).to have_css(".content > h1", text: "Apr-1 - Jun-30 (Q2 2024)")
        expect(panel).to have_css(".step-block .edit-indicator-summary")
        expect(panel).to have_css(".step-block .edit-target-summary")
        expect(panel).to have_css("textarea.custom-actions-list")
        expect(panel).to have_css(".action-buttons-block .cancel-button", text: "Cancel")
        expect(panel).to have_css(".action-buttons-block .save-button .loading-animation")
        expect(panel).to have_css(".action-buttons-block .save-button .button-text", text: "Save")
      end
    end

    it "renders the edit panel as an accessible labelled modal with an error message" do
      Timecop.freeze(Time.zone.parse("April 15 2024 15:12")) do
        action_plan

        render_inline(described_class.new(periods, region, default_options.merge(selected_quarter: q2_2024)))

        panel = page.find("#dr-rai--edit-sidebar")
        expect(panel["role"]).to eq("dialog")
        expect(panel["aria-modal"]).to eq("true")
        expect(panel["aria-labelledby"]).to eq("dr-rai--edit-title")
        expect(panel["aria-hidden"]).to eq("true")
        expect(panel["inert"]).to eq("")
        expect(panel).to have_css(".header > p#dr-rai--edit-title", text: "Edit action")
        expect(panel).to have_css(".missing-input-warning.edit-save-warning.d-none", text: "Unable to save. Try again.")
      end
    end

    it "removes and restores the edit panel accessibility guards when toggled" do
      Timecop.freeze(Time.zone.parse("April 15 2024 15:12")) do
        action_plan

        render_inline(described_class.new(periods, region, default_options.merge(selected_quarter: q2_2024)))

        markup = page.native.to_html
        expect(markup).to include("$(canvas).attr('aria-hidden', 'false').removeAttr('inert')")
        expect(markup).to include("canvas.attr('aria-hidden', 'true').attr('inert', '')")
      end
    end

    it "restores focus to the visible action-card toggle after editing and to the opener after creating" do
      Timecop.freeze(Time.zone.parse("April 15 2024 15:12")) do
        action_plan

        render_inline(described_class.new(periods, region, default_options.merge(selected_quarter: q2_2024)))

        markup = page.native.to_html
        expect(markup).to include("$(this).closest('.action-card').find('[data-toggle=\"dropdown\"]').get(0)")
        expect(markup).to include(": e.currentTarget")
        expect(markup).to include("$(canvas).data('opener', opener)")
        expect(markup).to include("opener.focus()")
      end
    end

    it "renders a fixed overlay for the offcanvas panels" do
      Timecop.freeze(Time.zone.parse("April 15 2024 15:12")) do
        render_inline(described_class.new(periods, region, default_options.merge(selected_quarter: q2_2024)))

        expect(page).to have_css(".bs-canvas-overlay.position-fixed.w-100.h-100", visible: :all)
      end
    end

    it "shows edit controls during the current quarter's second month" do
      Timecop.freeze(Time.zone.parse("May 1 2024 15:12")) do
        action_plan

        render_inline(described_class.new(periods, region, default_options.merge(selected_quarter: q2_2024)))

        expect(page).to have_css(".edit-action-plan")
      end
    end

    it "hides edit controls during the current quarter's last month" do
      Timecop.freeze(Time.zone.parse("June 1 2024 15:12")) do
        action_plan

        render_inline(described_class.new(periods, region, default_options.merge(selected_quarter: q2_2024)))

        expect(page).not_to have_css(".edit-action-plan")
      end
    end
  end

  describe "stale periods" do
    it "does not allow adding new actions" do
      rai_options = default_options.merge(selected_quarter: q1_2024)
      comp = described_class.new(periods, region, rai_options)
      the_page = render_inline(comp)
      add_action_button = the_page.css(".add-action-button")
      expect(add_action_button).to be_empty
    end
  end

  describe "current period" do
    it "allows new actions to be added" do
      rai_options = default_options.merge(selected_quarter: q2_2024)
      comp = described_class.new(periods, region, rai_options)
      the_page = render_inline(comp)
      add_action_button = the_page.css(".add-action-button")
      expect(add_action_button).not_to be_empty
    end
  end
end
