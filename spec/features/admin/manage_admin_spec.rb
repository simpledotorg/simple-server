require 'rails_helper'

RSpec.feature 'Admin Management', type: :feature do
  let(:owner) {create(:admin, :owner)}
  let!(:organizations) {FactoryBot.create_list(:organization, 2)}
  let!(:facility_group) {FactoryBot.create_list(:facility_group, 5)}

  admin_page = AdminPage.new
  invitation_page = InvitationPage.new
  set_pwd_page = SetPassword.new

  describe "Manage Admin Section" do

    before(:each) do
      visit root_path
      signin(owner)
      visit admins_path
    end

    it 'verify admin landing page' do
      invitation_permission=["Owner","Organization Owner","Supervisor","Analyst","Counsellor"]
      admin_page.verify_admin_landing_page(invitation_permission)
      expect(page).to have_content("Email")
      expect(page).to have_content("Role")
      expect(admin_page.admin_list).equal?(1)
    end

    context "Onwer" do
      let(:owner_email) {'owner@example.com'}

      it "send invitation" do
        admin_page.send_invite("Invite Owner")
        invitation_page.send_invitation_to_owner("owner@example.com")
        admin_page.successful_message
        admin_page.click_message_cross_button
        expect(page).to have_content("owner@example.com")
        expect(page).to have_content("Invitation sent")
      end

      #need to data drive invalid test data
      it "send invitation - invalid data" do
        admin_page.send_invite("Invite Owner")
        invitation_page.send_invitation_to_owner("owner@example")
        invitation_page.invalid_feedback
      end
    end

    context "Organization owner" do
      it "send invitation" do
        admin_page.send_invite("Invite Organization Owner")
        invitation_page.send_invitation_organization_owner("org@example.com", organizations.first.name)
        admin_page.successful_message
        admin_page.click_message_cross_button
        expect(page).to have_content("org@example.com")
        expect(page).to have_content("Invitation sent")
      end

      #need to data drive invalid test data
      it "send invitation with invalid data" do
        admin_page.send_invite("Invite Organization Owner")
        invitation_page.send_invitation_organization_owner("org@example", organizations.first.name)
        invitation_page.invalid_feedback
      end
    end

    context "Supervisor" do
      it "send invitation" do
        admin_page.send_invite("Invite Supervisor")
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

    it "owner should be able to create invite for organization's owner with multiple organization" do
      admin_page.send_invite("Invite Organization Owner")
      org = [organizations.first.name, organizations.second.name]
      invitation_page.select_invite_multiple_organization("org@example.com", org)
      admin_page.successful_message
      admin_page.click_message_cross_button
      expect(page).to have_content("org@example.com")
      expect(page).to have_content("Invitation sent")
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
    let(:test_admin) {Admin.invite!(email: "owner@example.com", role: :owner)}
    it "Accept invitation" do
      visit accept_admin_invitation_path(invitation_token: test_admin.raw_invitation_token)
      set_pwd_page.set_password("new_password")
      expect(test_admin.reload.invited_to_sign_up?).to eq(false)
      print page.html
    end

    let(:test_analyst) {Admin.invite!(email: "analyst@example.com", role: :analyst)}
    it "Accept invitation" do
      visit accept_admin_invitation_path(invitation_token: test_analyst.raw_invitation_token)
      set_pwd_page.set_password("new_password")
      expect(test_analyst.reload.invited_to_sign_up?).to eq(false)
    end
  end
end