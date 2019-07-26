require 'rails_helper'

RSpec.feature 'test protocol screen functionality', type: :feature do
  let(:owner) {create(:admin)}
  let!(:var_protocol) {create(:protocol, name: "PunjabTestProtocol", follow_up_days: "20")}

  protocol_page = ProtocolLandingPage.new
  protocol_form = ProtocolFormPage.new
  protocol_detail = ProtocolDetailPage.new

  before(:each) do
    visit root_path
    LoginPage.new.do_login(owner.email, owner.password)
    visit admin_protocols_path
  end

  context "protocol landing page" do
    it 'add new  protocol' do
      protocol_page.click_add_new_protocol
      protocol_form.create_new_protocol("testProtocol", "40")
      protocol_detail.verify_successful_message("Protocol was successfully created.")
      protocol_detail.click_message_cross_button
      #assertion
      expect(page).to have_content("testProtocol")
    end
    it 'edit protocol' do
      protocol_page.click_edit_protocol_link(var_protocol.name)
      protocol_form.update_protocol_followup_days(40)
      protocol_detail.verify_updated_followup_days("40")
      visit admin_protocols_path

      # assertion at landing page
      within(:xpath, "//a[text()='#{var_protocol.name}']/../../..") do
        expect(page).to have_content("Edit")
        expect(page).to have_selector("a.btn-outline-danger")
        expect(page).to have_content("40")
      end
    end
  end
end
