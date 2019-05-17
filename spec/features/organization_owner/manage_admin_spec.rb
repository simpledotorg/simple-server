require 'rails_helper'
require 'Pages/log_in_page'
require 'Pages/admin_page'
require 'Pages/invitaiton_page'
require 'Pages/set_password'

RSpec.feature 'Manage Section: Admin Management', type: :feature do

  let!(:ihmi) {create(:organization, name: "IHMI")}
  let!(:facility_group) {FactoryBot.create_list(:facility_group, 5,organization: ihmi)}

  let!(:org_owner) {
    create(
        :admin,
        :organization_owner,
        admin_access_controls: [AdminAccessControl.new(access_controllable: ihmi)])
  }

  admin_page = AdminPage.new
  invitation_page = InvitationPage.new
  set_pwd_page = SetPassword.new

  describe "Manage Admin Section" do
    before(:each) do
      visit root_path
      signin(org_owner)
      visit admins_path
    end

    it 'verify organizations owners Admin landing page' do
      invitation_permission=["Organization Owner","Supervisor","Analyst","Counsellor"]
      admin_page.verify_admin_landing_page(invitation_permission)
      expect(page).to have_content("Email")
      expect(page).to have_content("Role")
      expect(admin_page.admin_list).equal?(1)
    end

    context "Organization owner" do
      it "send invitation" do
        admin_page.send_invite("Invite Organization Owner")
        invitation_page.send_invitation_organization_owner("org@example.com", ihmi.name)
        admin_page.successful_message
        admin_page.click_message_cross_button
        expect(page).to have_content("org@example.com")
        expect(page).to have_content("Invitation sent")
      end

      #need to data drive invalid test data
      it "send invitation with invalid data" do
        admin_page.send_invite("Invite Organization Owner")
        invitation_page.send_invitation_organization_owner("org@example", ihmi.name)
        invitation_page.invalid_feedback
      end
    end

    context "Supervisor" do
      it "send invitation" do
        admin_page.send_invite("Invite Supervisor")
        print page.html
        invitation_page.send_invitation_others("super@example.com", facility_group.first.name)
        admin_page.successful_message
        admin_page.click_message_cross_button
        expect(page).to have_content("super@example.com")
        expect(page).to have_content("Invitation sent")
      end
      #need to data drive invalid test data
      it "send invitation with invalid data" do
        admin_page.send_invite("Invite Supervisor")
        invitation_page.send_invitation_others("super@example", facility_group.first.name)
        invitation_page.invalid_feedback
      end
    end

    context "Analyst" do
      it "send invitation" do
        admin_page.send_invite("Invite Analyst")
        invitation_page.send_invitation_others("analyst@example.com", facility_group.third.name)
        admin_page.successful_message
        admin_page.click_message_cross_button
        expect(page).to have_content("analyst@example.com")
        expect(page).to have_content("Invitation sent")
      end

      #need to data drive invalid test data
      it "send invitation with invalid data" do
        admin_page.send_invite("Invite Analyst")
        invitation_page.send_invitation_others("analyst@example", facility_group.third.name)
        invitation_page.invalid_feedback
      end
    end

    context "Counsellor" do
      it "send invitation" do
        admin_page.send_invite("Invite Counsellor")
        invitation_page.send_invitation_others("counsellor@example.com", facility_group.third.name)
        admin_page.successful_message
        admin_page.click_message_cross_button
        expect(page).to have_content("counsellor@example.com")
        expect(page).to have_content("Invitation sent")
      end
      #need to data drive invalid test data
      it "send invitation with invalid data" do
        admin_page.send_invite("Invite Counsellor")
        invitation_page.send_invitation_others("counsellor@example", facility_group.third.name)
        invitation_page.invalid_feedback
      end
    end

    it "owner should be able to create invite for Supervisor with multiple faiclity" do
      admin_page.send_invite("Invite Supervisor")
      facilities = [facility_group.first.name, facility_group.third.name]
      invitation_page.send_multiple_invitation_others("super@example.com", facilities)
      admin_page.successful_message
      admin_page.click_message_cross_button
      expect(page).to have_content("super@example.com")
    end
  end

  context "Accept Invitation" do
    let(:test_admin) {Admin.invite!(email: "owner@example.com", role: :organization_owner)}
    it "Accept invitation" do
      visit accept_admin_invitation_path(invitation_token: test_admin.raw_invitation_token)
      set_pwd_page.set_password("new_password")
      expect(test_admin.reload.invited_to_sign_up?).to eq(false)
      print page.html
    end
    let(:test_analyst) {Admin.invite!(email: "analyst@example.com", role: :counsellor)}
    it "Accept invitation" do
      visit accept_admin_invitation_path(invitation_token: test_analyst.raw_invitation_token)
      set_pwd_page.set_password("new_password")
      expect(test_analyst.reload.invited_to_sign_up?).to eq(false)
    end
  end
end