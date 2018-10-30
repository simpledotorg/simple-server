require 'rails_helper'

RSpec.feature 'Admin::AuditLogs', type: :feature do
  let(:admin_email) { 'user@test.com' }
  let(:admin_password) { 'password' }
  let(:admin) { create(:admin, email: admin_email, password: admin_password) }

  it 'Display Empty table when user name is empty' do
    login_as admin, :scope => :admin
    visit '/admin/audit_logs'
    fill_in "user_name", with: ""
    click_button 'Search'

    expect(page).not_to have_selector('tbody tr')
  end

  describe 'User name is entered' do
    let(:priyanka) { FactoryBot.create(:user, full_name: 'Dr. Priyanka Sodhi') }
    let(:yash) { FactoryBot.create(:user, full_name: 'Yash Bahl') }
    let(:rohit) { FactoryBot.create(:user, full_name: 'Rohit Mehra') }

    it 'Display audit logs for all the users containing the entered user name as a substring' do
      FactoryBot.create_list(:audit_log, 5, user: priyanka)
      FactoryBot.create_list(:audit_log, 5, user: yash)
      FactoryBot.create_list(:audit_log, 5, user: rohit)
      login_as admin, :scope => :admin
      visit '/admin/audit_logs'
      fill_in 'user_name', with: 'Ya'
      click_button 'Search'

      expect(page).to have_selector('tbody tr', count: 10)
      expect(page).to have_selector('tbody tr', text: 'Dr. Priyanka Sodhi')
      expect(page).to have_selector('tbody tr', text: 'Yash Bahl')
      expect(page).not_to have_selector('tbody tr', text: 'Rohit Mehra')
    end
  end
end
