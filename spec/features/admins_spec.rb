require 'rails_helper'

RSpec.feature "Admins", type: :feature do
  let!(:owner) { create(:admin, :owner, email: "owner@example.com") }
  let!(:supervisor) { create(:admin, :supervisor, email: "supervisor@example.com") }

  describe "index" do
    before { sign_in(owner) }

    it "shows all admins and roles" do
      visit admins_path

      expect(page).to have_content("Admins")

      within("tr", text: "owner@example.com") do
        expect(page).to have_content("Owner")
      end

      within("tr", text: "supervisor@example.com") do
        expect(page).to have_content("Supervisor")
      end
    end
  end

  describe "sending invitations to supervisors" do
    let(:email) { "new@example.com" }
    let(:new_supervisor) { Admin.find_by(email: email) }
    let!(:facility_groups) { FactoryBot.create_list(:facility_group, 2) }

    before do
      sign_in(owner)

      visit admins_path

      click_link "Invite Supervisor"

      fill_in "Email", with: email

      check facility_groups.first.name

      click_button "Send an invitation"
    end

    it "allows sending new invitations" do
      within("tr", text: email) do
        expect(page).to have_content("Supervisor")
        expect(page).to have_content("Invitation sent")
      end
    end

    it "sends an invite email" do
      invite_email = ActionMailer::Base.deliveries.last

      expect(invite_email.subject).to match(/Invitation/)
      expect(invite_email.body.encoded).to match(/Accept invitation/)
    end

    it "creates the user pending invitation" do
      expect(new_supervisor.invited_to_sign_up?).to eq(true)
    end
  end

  describe "sending invitations to organization owners" do
    let(:email) { "new@example.com" }
    let(:new_supervisor) { Admin.find_by(email: email) }
    let!(:organizations) { FactoryBot.create_list(:organization, 2) }

    before do
      sign_in(owner)

      visit admins_path

      click_link "Invite Organization Owner"

      fill_in "Email", with: email

      check organizations.first.name

      click_button "Send an invitation"
    end

    it "allows sending new invitations" do
      within("tr", text: email) do
        expect(page).to have_content("Organization owner")
        expect(page).to have_content("Invitation sent")
      end
    end

    it "sends an invite email" do
      invite_email = ActionMailer::Base.deliveries.last

      expect(invite_email.subject).to match(/Invitation/)
      expect(invite_email.body.encoded).to match(/Accept invitation/)
    end

    it "creates the user pending invitation" do
      expect(new_supervisor.invited_to_sign_up?).to eq(true)
    end
  end


  describe "association admins with their access control groups" do
    let(:email) { "new@example.com" }
    let(:new_supervisor) { Admin.find_by(email: email) }

    before do
      sign_in(owner)
      visit admins_path

    end

    describe "inviting supervisors" do
      let!(:facility_groups) { FactoryBot.create_list(:facility_group, 2) }
      before do
        click_link "Invite Supervisor"
        fill_in "Email", with: email
        check facility_groups.first.name
        click_button "Send an invitation"
      end

      it "associates new supervisors to facility groups" do
        expect(new_supervisor.admin_access_controls.count).to eq(1)
        expect(new_supervisor.admin_access_controls.first.access_controllable_type).to eq('FacilityGroup')
        expect(new_supervisor.admin_access_controls.first.access_controllable_id).to eq(facility_groups.first.id)
      end
    end

    describe "inviting analysts" do
      let!(:facility_groups) { FactoryBot.create_list(:facility_group, 2) }
      before do
        click_link "Invite analyst"
        fill_in "Email", with: email
        check facility_groups.first.name
        click_button "Send an invitation"
      end

      it "associates new analysts to facility groups" do
        expect(new_supervisor.admin_access_controls.count).to eq(1)
        expect(new_supervisor.admin_access_controls.first.access_controllable_type).to eq('FacilityGroup')
        expect(new_supervisor.admin_access_controls.first.access_controllable_id).to eq(facility_groups.first.id)
      end
    end

    describe "inviting organization_owners" do
      let!(:organizations) { FactoryBot.create_list(:organization, 2) }
      before do
        click_link "Invite Organization Owner"
        fill_in "Email", with: email
        check organizations.first.name
        click_button "Send an invitation"
      end

      it "associates new supervisors to facility groups" do
        expect(new_supervisor.admin_access_controls.count).to eq(1)
        expect(new_supervisor.admin_access_controls.first.access_controllable_type).to eq('Organization')
        expect(new_supervisor.admin_access_controls.first.access_controllable_id).to eq(organizations.first.id)
      end

    end
  end

  describe "accepting invitations" do
    let(:email) { "new@example.com" }
    let(:new_supervisor) { Admin.invite!(email: email, role: :supervisor) }

    it "allows the user to set a password" do
      visit accept_admin_invitation_path(invitation_token: new_supervisor.raw_invitation_token)

      fill_in "Password", with: "new_password"
      fill_in "Password confirmation", with: "new_password"

      click_button "Set my password"

      expect(new_supervisor.reload.invited_to_sign_up?).to eq(false)
    end
  end
end
