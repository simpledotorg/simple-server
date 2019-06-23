require 'rails_helper'

RSpec.feature "Admins", type: :feature do
  let!(:owner) { create(:master_user, :with_email_authentication, email: "owner@example.com") }
  let!(:supervisor) { create(:master_user, :with_email_authentication, email: "supervisor@example.com") }

  describe "index" do
    before { sign_in(owner.email_authentication) }

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

  describe "editing admins" do
    let!(:facility_group) { create(:facility_group, name: "CHC Buccho") }
    let!(:other_facility_group) { create(:facility_group, name: "PHC Ubha") }
    let!(:counsellor) { create( :admin, :counsellor) }

    before do
      sign_in(owner.email_authentication)
      visit edit_admin_path(counsellor)
    end

    it "should allow changing facility groups" do
      check "CHC Buccho"
      click_button "Update Admin"

      expect(counsellor.reload.facility_groups).to include(facility_group)
      expect(counsellor.facility_groups).not_to include(other_facility_group)
    end
  end

  describe "sending invitations to supervisors" do
    let(:email) { "new@example.com" }
    let(:new_supervisor) { Admin.find_by(email: email) }
    let!(:facility_groups) { FactoryBot.create_list(:facility_group, 2) }

    before do
      sign_in(owner.email_authentication)

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
      sign_in(owner.email_authentication)

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
      sign_in(owner.email_authentication)
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

    describe "inviting Analyst" do
      let!(:facility_groups) { FactoryBot.create_list(:facility_group, 2) }
      before do
        click_link "Invite Analyst"
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

  describe 'inviting Counsellors' do
    let!(:organization_owner) { create(:master_user, :with_email_authentication) }
    let!(:organization) { organization_owner.organizations.first }
    let!(:facility_group) { create(:facility_group, organization: organization) }
    let!(:email) { 'new_counsellor@example.com' }


    before do
      sign_in(organization_owner)
      visit admins_path

      click_link 'Invite Counsellor'
      fill_in 'Email', with: email
      check facility_group.name
      click_button 'Send an invitation'
    end

    it 'associates new counsellor to facility group' do
      new_counsellor = Admin.find_by(email: email)

      expect(new_counsellor.admin_access_controls.count).to eq(1)
      expect(new_counsellor.admin_access_controls.first.access_controllable_type).to eq('FacilityGroup')
      expect(new_counsellor.admin_access_controls.first.access_controllable_id).to eq(facility_group.id)
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
