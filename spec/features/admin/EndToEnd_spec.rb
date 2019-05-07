require 'rails_helper'
require 'Pages/log_in_page'
require 'Pages/protocol_landing_page'
require 'Pages/protocol_form'
require 'Pages/base'
require 'Pages/protocol_detail_page'
require 'Pages/protocol_drug_page'

RSpec.feature 'End to end test', type: :feature do

  let(:owner) {create(:admin)}
  let!(:ihmi) {create(:organization, name: "IHMI")}
  let!(:protocol) {create(:protocol, name: "PunjabTestProtocol", follow_up_days: "20")}
  let!(:ihmi_group_bathinda) {create(:facility_group, organization: ihmi, name: "Bathinda",protocol:protocol)}
  protocol_page = ProtocolLandingPage.new
  protocol_form = ProtocolFormPage.new
  protocol_detail = ProtocolDetailPage.new

  before(:each) do
    visit root_path
    LoginPage.new.do_login(owner.email, owner.password)
  end

  it 'update protocol and verify it for assigned facility group' do
    visit admin_protocols_path
    #updating protocol
    protocol_page.click_edit_protocol_link(protocol.name)
    protocol_form.update_protocol_name("Maharastra_protocol")
    protocol_detail.verify_successful_message("Protocol was successfully updated.")

    #visit facility page
    visit admin_facilities_path
    expect(page).to have_content("Maharastra_protocol")
  end
end