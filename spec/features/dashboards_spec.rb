require 'rails_helper'

RSpec.feature "Dashboards", type: :feature do
  let!(:supervisor) { create(:admin, :supervisor, email: "supervisor@example.com") }

  before do
    sign_in(supervisor)
    visit admin_dashboard_path
  end

  it "shows a basic dashboard" do
  end
end
