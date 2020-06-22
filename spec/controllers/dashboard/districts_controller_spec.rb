require "rails_helper"

RSpec.describe Dashboard::DistrictsController, type: :controller do
  let(:organization) { FactoryBot.create(:organization) }
  let(:supervisor) do
    create(:admin, :organization_owner, organization: organization).tap do |user|
      user.user_permissions.create!(permission_slug: "view_my_facilities")
    end
  end

  context "preview" do
    render_views

    it "does not render for anonymous" do
      get :preview
      expect(response).to_not be_successful
    end

    it "renders for admins" do
      sign_in(supervisor.email_authentication)
      get :preview
      expect(response).to be_successful
    end
  end

  context "show" do
    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
    end

    it "retrieves data" do
      jan_2020 = Time.parse("January 1 2020")
      patient = create(:patient, registration_facility: @facility, recorded_at: jan_2020.advance(months: -1))
      create(:blood_pressure, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: @facility)
      create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility)
      LatestBloodPressuresPerPatient.refresh
      LatestBloodPressuresPerPatientPerMonth.refresh

      sign_in(supervisor.email_authentication)
      get :show, params: {id: @facility.facility_group.slug}
      expect(response).to be_successful
      data = assigns(:data)
      expect(data[:controlled_patients].size).to eq(12) # 1 year of data
      expect(data[:controlled_patients]["Dec 2019"]).to eq(1)
    end
  end
end
