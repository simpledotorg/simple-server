require 'rails_helper'

RSpec.feature 'test protocol screen functionality', type: :feature do
  let(:owner) {create(:admin)}
  let!(:var_protocol) {create(:protocol, name: "PunjabTestProtocol", follow_up_days: "20")}

  protocol_page = AdminProtocolPage.new
  protocol_new = AdminProtocolPageNew.new
  protocol_detail_page = ProtocolDetailPage.new

  before(:each) do
    visit root_path
    sign_in(owner)
    visit admin_protocols_path
  end

  context "protocol landing page" do
    it 'add new  protocol' do
      protocol_page.click_add_new_protocol
      protocol_new.create_new_protocol("testProtocol", "40")

      protocol_detail_page.verify_successful_message("Protocol was successfully created.")
      protocol_detail_page.click_message_cross_button
      #assertion
      expect(page).to have_content("testProtocol")
    end

    it 'edit protocol' do
      protocol_page.click_edit_protocol_link(var_protocol.name)
      AdminProtocolPageEdit.new.update_protocol_followup_days(40)
      protocol_detail_page.verify_updated_followup_days("40")

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
