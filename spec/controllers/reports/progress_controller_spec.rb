require "rails_helper"

RSpec.describe Reports::ProgressController, type: :controller do
  let(:jan_2020) { Time.parse("January 1 2020") }
  let(:dec_2019_period) { Period.month(Date.parse("December 2019")) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:cvho) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:call_center_user) { create(:admin, :call_center, full_name: "call_center") }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }
  let(:facility_1) { FactoryBot.create(:facility, name: "facility_1", facility_group: facility_group_1) }

  describe "show" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
      @facility_region = @facility.region
    end

    it "redirects if user does not have proper access to org" do
      district_official = create(:admin, :viewer_reports_only, :with_access, resource: @facility_group)

      sign_in(district_official.email_authentication)
      get :show, params: {id: @facility_group.organization.slug, report_scope: "organization"}
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      expect(response).to be_redirect
    end

    it "renders successfully if report viewer has access to region" do
      other_fg = create(:facility_group, name: "other facility group", organization: organization)
      facility = create(:facility, name: "other facility", facility_group: other_fg)
      user = create(:admin, :viewer_reports_only, :with_access, resource: other_fg)

      sign_in(user.email_authentication)
      get :show, params: {id: facility.region.slug}
      expect(response).to be_successful
    end

    it "returns period info for every month" do
      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.facility_group.region.slug, report_scope: "district"}
      end
      data = assigns(:data)
      period_hash = {
        name: "Dec-2019",
        bp_control_start_date: "1-Oct-2019",
        bp_control_end_date: "31-Dec-2019",
        ltfu_since_date: "31-Dec-2018",
        bp_control_registration_date: "30-Sep-2019"
      }
      expect(data[:period_info][dec_2019_period]).to eq(period_hash)
    end

    it "returns period info for current month" do
      today = Date.current
      Timecop.freeze(today) do
        patient = create(:patient, registration_facility: @facility, recorded_at: 2.months.ago)
        create(:bp_with_encounter, :under_control, recorded_at: Time.current.yesterday, patient: patient, facility: @facility)
        refresh_views
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility.facility_group.slug, report_scope: "district"}
      end
      data = assigns(:data)
      expect(data[:period_info][Period.month(today.beginning_of_month)]).to_not be_nil
    end

    it "retrieves facility data" do
      Time.parse("January 1 2020")
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -4))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        sign_in(cvho.email_authentication)
        get :show, params: {id: @facility_region.slug, report_scope: "facility"}
      end
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients].size).to eq(10) # sanity check
      expect(data[:controlled_patients][Date.parse("Dec 2019").to_period]).to eq(1)
    end

    it "works when a user requests data just before the earliest registration date" do
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -4))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: @facility)
      refresh_views
      one_month_before = patient.recorded_at.advance(months: -1)

      sign_in(cvho.email_authentication)
      get :show, params: {id: @facility_region.slug, report_scope: "facility",
                          period: {type: :month, value: one_month_before}}
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients]).to eq({})
      expect(data[:period_info]).to eq({})
    end
  end
end