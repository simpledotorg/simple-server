require "rails_helper"

RSpec.describe Dashboard::DistrictsController, type: :controller do
  let(:supervisor) do
    create(:admin, :supervisor).tap do |user|
      user.user_permissions.create!(permission_slug: "view_my_facilities")
    end
  end

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
