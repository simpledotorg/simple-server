require 'rails_helper'

RSpec.feature 'Admin::Login', type: :feature do
  let(:admin) { create(:admin) }

  it 'Log in and see dashboard by default' do
    FactoryBot.create(:user, sync_approval_status: :requested)

    visit '/'

    fill_in 'Email', with: admin.email
    fill_in 'Password', with: admin.password

    click_button 'Login'

    expect(current_path).to eq(admin_root_path)
  end

  it 'Log out and go back to login screen' do
    sign_in(admin)
    visit admin_facilities_path

    click_link 'Logout'

    expect(current_path).to eq(root_path)
    expect(page).to have_content('Login')
  end
end
