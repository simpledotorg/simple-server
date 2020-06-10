require "rails_helper"

RSpec.describe ReportsController, type: :controller do
  let(:supervisor) do
    create(:admin, :supervisor).tap do |user|
      user.user_permissions.create!(permission_slug: "view_my_facilities")
    end
  end

  before do
    @facility = create(:facility, name: "CHC Barnagar")
  end

  context "rendering" do
    render_views

    it "does not render for anonymous" do
      get :index
      expect(response).to_not be_successful
    end

    it "renders for admins" do
      sign_in(supervisor.email_authentication)
      get :index
      expect(response).to be_successful
    end
  end

  it "retrieves data" do
    jan_2020 = Time.parse("January 1 2020")
    create(:blood_pressure, :under_control, recorded_at: jan_2020, facility: @facility).create_or_update_rollup
    create(:blood_pressure, :hypertensive, recorded_at: jan_2020, facility: @facility).create_or_update_rollup
    LatestBloodPressuresPerPatient.refresh
    LatestBloodPressuresPerPatientPerMonth.refresh

    sign_in(supervisor.email_authentication)
    get :index
    expect(response).to be_successful
    data = assigns(:data)
    expect(data[:controlled_patients].size).to eq(12) # 1 year of data
    expect(data[:controlled_patients]["Jan 2020"]).to eq(1)
    expect(data[:controlled_patients]["Mar 2020"]).to eq(1)
  end
end
