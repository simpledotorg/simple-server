require 'rails_helper'

RSpec.feature 'test protocol detail page functionality', type: :feature do

  let(:owner) { create(:admin) }
  protocol_page = ProtocolLandingPage.new
  protocol_form = ProtocolFormPage.new
  protocol_detail = ProtocolDetailPage.new
  protocol_drug = ProtocolDrugPage.new

  before(:each) do
    visit root_path
    signin(owner)
    visit admin_protocols_path
    protocol_page.click_add_new_protocol
    protocol_form.create_new_protocol("testProtocol", "40")
  end

  context "protocol detail page" do
    it " edit protocol" do
      protocol_detail.click_edit_protocol_button
      protocol_form.update_protocol_followup_days("10")
      #assertion
      protocol_detail.verify_successful_message("Protocol was successfully updated.")
      protocol_detail.verify_updated_followup_days("10")
      protocol_detail.click_message_cross_button
    end
    it 'should create new protocol drug ' do
      protocol_detail.click_new_protocol_drug_button
      protocol_drug.add_new_protocol_drug("test_drug", "10mg", "AXDSC")
      #assertion
      protocol_detail.verify_successful_message("Protocol drug was successfully created.")
      drug_info = ["test_drug", "10mg","AXDSC"]
      protocol_detail.verify_protocol_drug_info(drug_info)
    end
    it 'should edit protocol drug' do
      protocol_detail.click_new_protocol_drug_button
      protocol_drug.add_new_protocol_drug("test_drug", "10mg", "AXDSC")
      protocol_detail.click_edit_protocol_drug_button("test_drug")
      protocol_drug.edit_protocol_drug_info("50mg", "AXDFC")
    end
  end
end