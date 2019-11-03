require 'rails_helper'

RSpec.xfeature "Admins", type: :feature do
  let(:full_name) { Faker::Name.name }
let!(:owner) { create(:admin, role: 'owner', email: "owner@example.com") }
  let!(:manage_admins_permission) { create(:user_permission, user: owner, permission_slug: :manage_admins) }

  let!(:supervisor) { create(:admin, :supervisor, email: "supervisor@example.com") }

  describe "index" do
    before { sign_in(owner.email_authentication) }

    it "shows all email_authentications and roles" do
      visit admins_path

      expect(page).to have_content("Admins")

      within(".card", text: "owner@example.com") do
        expect(page).to have_content("Owner")
      end

      within(".card", text: "supervisor@example.com") do
        expect(page).to have_content("Supervisor")
      end
    end
  end

  describe "editing email_authentications" do
    let!(:facility_group) { create(:facility_group, name: "CHC Buccho") }
    let!(:other_facility_group) { create(:facility_group, name: "PHC Ubha") }
    let!(:counsellor) { create(:admin, :counsellor) }

    before do
      sign_in(owner.email_authentication)
      visit edit_admin_path(counsellor)
    end

    xit "should allow changing facility groups" do
      check "CHC Buccho"
      click_button "Update Admin"

      expect(counsellor.reload.resources).to include(facility_group)
      expect(counsellor.resources).not_to include(other_facility_group)
    end
  end

  describe "sending invitations to supervisors" do
    let(:full_name) { Faker::Name.name }
    let(:email) { "new@example.com" }
    let(:new_supervisor) { User.joins(:email_authentications).find_by(email_authentications: { email: email }) }
    let!(:facility_groups) { FactoryBot.create_list(:facility_group, 2) }

    before do
      sign_in(owner.email_authentication)

      visit admins_path

      within ".modal" do
        click_link "Supervisor"
      end

      fill_in "Full name", with: full_name
      fill_in "Email", with: email

      check facility_groups.first.name

      click_button "Send an invitation"
    end

    it "allows sending new invitations" do
      within(".card", text: email) do
        expect(page).to have_content("Supervisor")
        expect(page).to have_content("Invite sent")
      end
    end

    it "sends an invite email" do
      invite_email = ActionMailer::Base.deliveries.last

      expect(invite_email.subject).to match(/Invitation/)
      expect(invite_email.body.encoded).to match(/ACCEPT INVITATION/)
    end

    it "creates the user pending invitation" do
      expect(new_supervisor.invited_to_sign_up?).to eq(true)
    end
  end

  describe "sending invitations to organization owners" do
    let(:full_name) { Faker::Name.name }
    let(:email) { "new@example.com" }
    let(:new_supervisor) { User.joins(:email_authentications).find_by(email_authentications: { email: email }) }
    let!(:organizations) { FactoryBot.create_list(:organization, 2) }

    before do
      sign_in(owner.email_authentication)

      visit admins_path

      within ".modal" do
        click_link "Organization Owner"
      end

      fill_in "Full name", with: full_name
      fill_in "Email", with: email

      check organizations.first.name

      click_button "Send an invitation"
    end

    it "allows sending new invitations" do
      within(".card", text: email) do
        expect(page).to have_content("Organization owner")
        expect(page).to have_content("Invite sent")
      end
    end

    it "sends an invite email" do
      invite_email = ActionMailer::Base.deliveries.last

      expect(invite_email.subject).to match(/Invitation/)
      expect(invite_email.body.encoded).to match(/ACCEPT INVITATION/)
    end

    it "creates the user pending invitation" do
      expect(new_supervisor.invited_to_sign_up?).to eq(true)
    end
  end

  describe "association email_authentications with their access control groups" do
    let(:full_name) { Faker::Name.name }
    let(:email) { "new@example.com" }
    let(:new_supervisor) { User.joins(:email_authentications).find_by(email_authentications: { email: email }) }

    before do
      sign_in(owner.email_authentication)
      visit admins_path
    end

    describe "inviting supervisors" do
      let!(:facility_groups) { FactoryBot.create_list(:facility_group, 2) }
      before do
        within ".modal" do
          click_link "Supervisor"
        end

        fill_in "Full name", with: full_name
        fill_in "Email", with: email
        check facility_groups.first.name
        click_button "Send an invitation"
      end

      it "associates new supervisors to facility groups" do
        expect(new_supervisor.user_permissions.count).to eq(4)
        expect(new_supervisor.user_permissions.first.resource_type).to eq('FacilityGroup')
        expect(new_supervisor.user_permissions.first.resource_id).to eq(facility_groups.first.id)
      end
    end

    describe "inviting Analyst" do
      let!(:facility_groups) { FactoryBot.create_list(:facility_group, 2) }
      before do
        within ".modal" do
          click_link "Analyst"
        end

        fill_in "Full name", with: full_name
        fill_in "Email", with: email
        check facility_groups.first.name
        click_button "Send an invitation"
      end

      it "associates new analysts to facility groups" do
        expect(new_supervisor.user_permissions.count).to eq(1)
        expect(new_supervisor.user_permissions.first.resource_type).to eq('FacilityGroup')
        expect(new_supervisor.user_permissions.first.resource_id).to eq(facility_groups.first.id)
      end
    end

    describe "inviting organization_owners" do
      let!(:organizations) { FactoryBot.create_list(:organization, 2) }
      before do
        within ".modal" do
          click_link "Organization Owner"
        end

        fill_in "Full name", with: full_name
        fill_in "Email", with: email
        check organizations.first.name
        click_button "Send an invitation"
      end

      it "associates new supervisors to facility groups" do
        expect(new_supervisor.user_permissions.count).to eq(4)
        expect(new_supervisor.user_permissions.first.resource_type).to eq('Organization')
        expect(new_supervisor.user_permissions.first.resource_id).to eq(organizations.first.id)
      end

    end
  end

  describe 'inviting Counsellors' do
    let!(:organization_owner) { create(:admin, :organization_owner) }
    let!(:organization) { organization_owner.resources.first }
    let!(:facility_group) { create(:facility_group, organization: organization) }
    let(:full_name) { Faker::Name.name }
    let!(:email) { 'new_counsellor@example.com' }


    before do
      sign_in(organization_owner.email_authentication)
      visit admins_path

      within ".modal" do
        click_link 'Counsellor'
      end

      fill_in "Full name", with: full_name
      fill_in 'Email', with: email
      check facility_group.name
      click_button 'Send an invitation'
    end

    it 'associates new counsellor to facility group' do
      new_counsellor = User.joins(:email_authentications).find_by(email_authentications: { email: email })

      expect(new_counsellor.user_permissions.count).to eq(3)
      expect(new_counsellor.user_permissions.first.resource_type).to eq('FacilityGroup')
      expect(new_counsellor.user_permissions.first.resource_id).to eq(facility_group.id)
    end
  end

  describe "accepting invitations" do
    let(:email) { "new@example.com" }
    let(:new_supervisor) { create(:admin, :supervisor)}
    let(:email_authentication) { EmailAuthentication.invite!(email: email, user: new_supervisor) }

    it "allows the user to set a password" do
      visit accept_email_authentication_invitation_path(invitation_token: email_authentication.raw_invitation_token)

      fill_in "Password", with: "new_password"
      fill_in "Password confirmation", with: "new_password"

      click_button "Set my password"

      expect(email_authentication.reload.invited_to_sign_up?).to eq(false)
    end
  end
end
