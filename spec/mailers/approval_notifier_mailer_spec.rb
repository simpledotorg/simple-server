require "rails_helper"
RSpec.describe ApprovalNotifierMailer, type: :mailer do
  describe "ApprovalNotifier emails" do
    let!(:new_power_user) { create(:admin, :power_user) }

    let!(:organization) { create(:organization) }
    let!(:org_manager) { create(:admin, :manager, :with_access, resource: organization) }
    let!(:unsubscribed_org_manager) { create(:admin, :manager, :with_access, resource: organization, receive_approval_notifications: false) }
    let!(:other_organization) { create(:organization) }
    let!(:other_org_manager) { create(:admin, :manager, :with_access, resource: other_organization) }

    let!(:facility_group) { create(:facility_group, organization: organization) }
    let!(:fg_manager) { create(:admin, :manager, :with_access, resource: facility_group) }
    let!(:unsubscribed_fg_manager) { create(:admin, :manager, :with_access, resource: facility_group, receive_approval_notifications: false) }
    let!(:other_facility_group) { create(:facility_group, organization: other_organization) }
    let!(:other_fg_manager) { create(:admin, :manager, :with_access, resource: other_facility_group) }

    let!(:facility) { create(:facility, facility_group: facility_group) }
    let!(:facility_manager) { create(:admin, :manager, :with_access, resource: facility) }
    let!(:unsubscribed_facility_manager) { create(:admin, :manager, :with_access, resource: facility, receive_approval_notifications: false) }
    let!(:other_facility) { create(:facility, facility_group: other_facility_group) }
    let!(:other_facility_manager) { create(:admin, :manager, :with_access, resource: other_facility) }

    let!(:user) { create(:user, :sync_requested, organization: organization, registration_facility: facility) }
    let!(:other_user) { create(:user, :sync_requested, organization: other_organization, registration_facility: other_facility) }

    describe "registration_approval_email" do
      context "non production env" do
        it "skips sending registration_approval_email" do
          allow(Rails.logger).to receive(:info)
          mail = described_class.registration_approval_email(user_id: user.id)

          expect(mail.subject).to be_nil
          expect(mail.to).to be_nil
          expect(Rails.logger).to have_received(:info).with("Non-production environment: skipped sending registration_approval_email")
        end
      end

      context "production env" do
        before { stub_const("SIMPLE_SERVER_ENV", "production") }

        let(:mail) { described_class.registration_approval_email(user_id: user.id) }

        it "renders the headers" do
          expect(mail.subject).to eq("New Registration: User #{user.full_name} is requesting access to #{organization.name} facilities.")
          expect(mail.from).to eq(["help@simple.org"])
          expect(mail.to).to contain_exactly(facility_manager.email, fg_manager.email)
          expect(mail.cc).to contain_exactly(org_manager.email)
          expect(mail.bcc).to include(new_power_user.email)
        end

        it "renders the body, and contains a link to the user's edit page" do
          expect(mail.body).to include("New User Registered")
          expect(mail.body).to include("/admin/users/#{user.id}")
        end
      end
    end

    describe "reset_password_approval_email" do
      let(:mail) { described_class.reset_password_approval_email(user_id: user.id) }

      it "renders the headers" do
        expect(mail.subject).to eq("PIN Reset: User #{user.full_name} is requesting access.")
        expect(mail.from).to eq(["help@simple.org"])
        expect(mail.to).to contain_exactly(facility_manager.email, fg_manager.email)
        expect(mail.cc).to contain_exactly(org_manager.email)
        expect(mail.bcc).to include(new_power_user.email)
      end

      it "renders the body, and contains a link to the user's edit page" do
        expect(mail.body).to include("User has reset PIN.")
        expect(mail.body).to include("/admin/users/#{user.id}")
      end
    end
  end
end
