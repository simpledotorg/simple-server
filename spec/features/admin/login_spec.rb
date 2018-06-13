require 'rails_helper'

RSpec.feature "Admin::Login", type: :feature do
  let(:admin) { create(:admin) }

  it "Log in and see facilities by default" do
    visit "/"

    fill_in "Email", with: admin.email
    fill_in "Password", with: admin.password

    click_button "Log in"

    expect(current_path).to eq(admin_facilities_path)
    expect(page).to have_selector("h1", text: "Facilities")
  end

  it "Log out and go back to login screen" do
    sign_in(admin)
    visit admin_facilities_path

    click_link "Log Out"

    expect(current_path).to eq(root_path)
    expect(page).to have_content("Log in")
  end
end
