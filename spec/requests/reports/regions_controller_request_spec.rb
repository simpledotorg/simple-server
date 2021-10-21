require "rails_helper"

RSpec.describe "RegionsControllers", type: :request do
  include Capybara::RSpecMatchers

  let(:jan_2020) { Time.zone.parse("January 1 2020") }
  let(:organization) { FactoryBot.create(:organization) }
  let(:cvho) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }
  let(:facility_1) { FactoryBot.create(:facility, name: "facility_1", facility_group: facility_group_1) }

  def refresh_views
    RefreshReportingViews.call
  end

  describe "GET /regions_controllers" do
    it "renders show" do
      facility_group = create(:facility_group, organization: organization)
      facility = create(:facility, name: "CC Brooklyn", facility_group: facility_group)
      region = facility.region
      patient = create(:patient, registration_facility: facility, recorded_at: jan_2020.advance(months: -4))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: facility)
      create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020, facility: facility)
      refresh_views

      Timecop.freeze("June 1 2020") do
        post email_authentication_session_path, params: {email_authentication: {email: cvho.email, password: cvho.password}}
        follow_redirect!

        get "/reports/regions"
        expect(response).to have_http_status(200)

        get "/reports/regions/facility/#{region.slug}"
        expect(response).to have_http_status(200)
        expect(response.body).to include("CC Brooklyn")
        doc = Nokogiri::HTML(response.body)
        json = doc.search("#data-json")
        data = Oj.load(json.text)

        # spot check for now
        keys = ["adjusted_patient_counts", "uncontrolled_patients_rate"]
        expect(data.keys).to include(*keys)
      end
    end
  end
end
