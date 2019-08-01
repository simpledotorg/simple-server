require 'rails_helper'

RSpec.feature 'test protocol detail page functionality', type: :feature do
    let(:owner) { create(:admin) }
    let!(:var_protocol) { create(:protocol, name: "PunjabTestProtocol", follow_up_days: "20") }
    let!(:var_protocol_drug) {create(:protocol_drug, name: "test_Drug_01", dosage: "10mg", rxnorm_code: "code",protocol: var_protocol)}

    protocol=AdminProtocolPage.new
    protocol_update = AdminProtocolPageEdit.new
    protocol_detail = ProtocolDetailPage.new
    new_drug = ProtocolDrugsPageNew.new

    before(:each) do
      visit root_path
      sign_in(owner)
      visit admin_protocols_path
    end

    context "protocol detail page" do
      it " edit protocol" do
        protocol.select_protocol(var_protocol.name)

        protocol_detail.click_edit_protocol_button
        protocol_update.update_protocol_followup_days("10")
        #assertion
        protocol_detail.verify_successful_message("Protocol was successfully updated.")
        protocol_detail.verify_updated_followup_days("10")
        protocol_detail.click_message_cross_button
      end
      it 'should create new protocol drug ' do
        protocol.select_protocol(var_protocol.name)

        protocol_detail.click_new_protocol_drug_button
        new_drug.add_new_protocol_drug("test_drug", "10mg", "AXDSC")
        #assertion
        protocol_detail.verify_successful_message("Protocol drug was successfully created.")
        protocol_detail.verify_protocol_drug_name_list("test_drug")
      end
      it 'should edit protocol drug' do
        protocol.select_protocol(var_protocol.name)
        protocol_detail.click_edit_protocol_drug_button("10mg test_Drug_01")
        ProtocolDrugPageEdit.new.edit_protocol_drug_info("50mg", "AXDFC")
      end
    end
  end
