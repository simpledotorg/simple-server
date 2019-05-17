require 'rails_helper'
require 'Pages/log_in_page'
require 'Pages/protocol_landing_page'
require 'Pages/protocol_detail_page'
require 'Pages/protocol_form'
require 'Pages/protocol_drug_page'


RSpec.feature 'Manage Section: Protocol Management', type: :feature do

  let!(:ihmi) {create(:organization, name: "IHMI")}
  let!(:protocol_01) {create(:protocol, name: "test_protocol1", follow_up_days: 20)}
  let!(:ihmi_group1) {create(:facility_group, organization: ihmi, name: "Bathinda", protocol: protocol_01)}
  let!(:ihmi_group2) {create(:facility_group, organization: ihmi, name: "Mansa", protocol: protocol_01)}


  let!(:test_org) {create(:organization, name: "IHMI")}
  let!(:protocol_02) {create(:protocol, name: "test_protocol2", follow_up_days: 20)}
  let!(:protocol_03) {create(:protocol, name: "test_protocol3", follow_up_days: 30)}
  let!(:facility_group1) {create(:facility_group, organization: test_org, name: "Bathinda", protocol: protocol_01)}
  let!(:facility_group2) {create(:facility_group, organization: test_org, name: "Mansa", protocol: protocol_02)}
  let!(:facility_group3) {create(:facility_group, organization: test_org, name: "Wardha", protocol: protocol_03)}

  # let!(:protocol_02_drug){ create(:ProtocolDrug, name: "amlodipine",dosage: "10mg")

  protocol_page = ProtocolLandingPage.new
  protocol_detail = ProtocolDetailPage.new
  protocol_form = ProtocolFormPage.new
  protocol_drug = ProtocolDrugPage.new

  context 'Verify protocol info for organization with multiple facility with same protocol' do
    let!(:org_owner) {
      create(
          :admin,
          :organization_owner,
          admin_access_controls: [AdminAccessControl.new(access_controllable: ihmi)])
    }

    it 'Protocol landing page' do
      visit root_path
      signin(org_owner)
      visit admin_protocols_path
      arr = [protocol_01.name, protocol_01.follow_up_days.to_s]
      protocol_page.verify_protocol_landing_page(arr)
    end
  end

  context 'Verify protocol info for organization with multiple facility with multiple protocol' do
    let!(:org_owner) {
      create(
          :admin,
          :organization_owner,
          admin_access_controls: [AdminAccessControl.new(access_controllable: test_org)])
    }

    before(:each) do
      visit root_path
      signin(org_owner)
      visit admin_protocols_path

    end
    it 'Protocol landing page' do
      arr = [protocol_01.name, protocol_01.follow_up_days.to_s, protocol_02.name, protocol_02.follow_up_days.to_s, protocol_03.name, protocol_03.follow_up_days.to_s]
      protocol_page.verify_protocol_landing_page(arr)
    end

    it "verify protocol detail page" do
      protocol_page.select_protocol(protocol_02.name)
      protocol_detail.verify_protocol_detail_page(protocol_02.name, protocol_02.follow_up_days.to_s)
      #need to verify protocol drug
    end
  end

  context "protocol drug" do
    let!(:org_owner) {
      create(
          :admin,
          :organization_owner,
          admin_access_controls: [AdminAccessControl.new(access_controllable: ihmi)])
    }

    before(:each) do
      visit root_path
      sigin(org_owner)
      visit admin_protocols_path
    end
    it "Add new protocol drug" do
      protocol_page.select_protocol(protocol_01.name)
      protocol_detail.click_new_protocol_drug_button
      protocol_drug.add_new_protocol_drug("test_drug", "10mg", "AXDSC")

      expect(page).to have_content("test_drug")
      expect(page).to have_content("10mg")
      expect(page).to have_content("AXDSC")
    end

    it "Edit protocol drug" do
      protocol_page.select_protocol(protocol_01.name)
      protocol_detail.click_new_protocol_drug_button
      protocol_drug.add_new_protocol_drug("test_drug", "10mg", "AXDSC")
      protocol_detail.click_edit_protocol_drug_button("test_drug")
      protocol_drug.edit_protocol_drug_info("50mg", "AXDFC")
    end
  end
end