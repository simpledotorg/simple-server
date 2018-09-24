require 'rails_helper'

RSpec.feature 'Admin::Login', type: :feature do
  let(:admin) { create(:admin) }

  it 'Log in and see dashboard by default' do
    visit '/'

    fill_in 'Email', with: admin.email
    fill_in 'Password', with: admin.password

    click_button 'Log in'

    expect(current_path).to eq(admin_dashboard_path)
    expect(page).to have_selector('h3', text: 'Users waiting for approval')
    expect(page).to have_selector('h3', text: 'Patients Registered')
  end

  it 'Log out and go back to login screen' do
    sign_in(admin)
    visit admin_facilities_path

    click_link 'Log Out'

    expect(current_path).to eq(root_path)
    expect(page).to have_content('Log in')
  end
end
