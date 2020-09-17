require "rails_helper"
RSpec.describe ApprovalNotifierMailer, type: :mailer do
  describe 'emails' do
    let!(:old_power_user) { create(:admin, :owner) }
    let!(:new_power_user) { create(:admin, :power_user) }
    let!(:organization) { create(:organization) }
    let!(:old_org_owner) { create(:admin, :organization_owner, organization: organization) }
    let!(:org_manager) { create(:admin, :manager) }
    let!(:org_manager_access) { create(:access, user: org_manager, resource: organization) }
    let!(:facility_group) { create(:facility_group, organization: organization) }
    let!(:old_fg_supervisor) { create(:admin, :supervisor, facility_group: facility_group) }
    let!(:fg_manager) { create(:admin, :manager) }
    let!(:fg_manager_access) { create(:access, user: fg_manager, resource: facility_group) }
    let!(:facility) { create(:facility, facility_group: facility_group) }
    let!(:facility_manager) { create(:admin, :manager) }
    let!(:facility_manager_access) { create(:access, user: facility_manager, resource: facility_group) }
    let!(:user) { create(:user, :sync_requested, organization: organization, registration_facility: facility) }

    describe "registration_approval_email" do
      let(:mail) { described_class.registration_approval_email(user_id: user.id) }

      it "renders the headers" do
        expect(mail.subject).to eq("New Registration: User #{user.full_name} is requesting access to #{organization.name} facilities.")
        expect(mail.from).to eq(["help@simple.org"])
        expect(mail.to).to contain_exactly(facility_manager.email, fg_manager.email, old_fg_supervisor.email)
        expect(mail.cc).to contain_exactly(org_manager.email, old_org_owner.email)
        expect(mail.bcc).to include(old_power_user.email, new_power_user.email)
      end

      it "renders the body, and contains a link to the user's edit page" do
        expect(mail.body).to include("New User Registered")
        expect(mail.body).to include("/admin/users/#{user.id}")
      end
    end

    describe "reset_password_approval_email" do
      let(:mail) { described_class.reset_password_approval_email(user_id: user.id) }

      it "renders the headers" do
        expect(mail.subject).to eq("PIN Reset: User #{user.full_name} is requesting access.")
        expect(mail.from).to eq(["help@simple.org"])
        expect(mail.to).to contain_exactly(facility_manager.email, fg_manager.email, old_fg_supervisor.email)
        expect(mail.cc).to contain_exactly(org_manager.email, old_org_owner.email)
        expect(mail.bcc).to include(old_power_user.email, new_power_user.email)
      end

      it "renders the body, and contains a link to the user's edit page" do
        expect(mail.body).to include("User has reset PIN.")
        expect(mail.body).to include("/admin/users/#{user.id}")
      end
    end
  end
end
