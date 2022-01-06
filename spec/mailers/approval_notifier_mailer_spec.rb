# frozen_string_literal: true

require "rails_helper"
RSpec.describe ApprovalNotifierMailer, type: :mailer do
  describe "ApprovalNotifier emails" do
    describe "registration_approval_email" do
      context "non production env" do
        it "skips sending registration_approval_email" do
          facility = create(:facility)

          user = create(:user, :sync_requested, organization: facility.organization, registration_facility: facility)

          allow(Rails.logger).to receive(:info)
          mail = described_class.registration_approval_email(user_id: user.id)

          expect(mail.subject).to be_nil
          expect(mail.to).to be_nil
          expect(Rails.logger).to have_received(:info).with("Non-production environment: skipped sending registration_approval_email")
        end
      end

      context "production env" do
        before { stub_const("SIMPLE_SERVER_ENV", "production") }

        it "sends the approval email" do
          new_power_user = create(:admin, :power_user)

          organization = create(:organization)
          org_manager = create(:admin, :manager, :with_access, resource: organization)
          _unsubscribed_org_manager = create(:admin, :manager, :with_access, resource: organization, receive_approval_notifications: false)
          other_organization = create(:organization)
          _other_org_manager = create(:admin, :manager, :with_access, resource: other_organization)

          facility_group = create(:facility_group, organization: organization)
          fg_manager = create(:admin, :manager, :with_access, resource: facility_group)
          _unsubscribed_fg_manager = create(:admin, :manager, :with_access, resource: facility_group, receive_approval_notifications: false)
          other_facility_group = create(:facility_group, organization: other_organization)
          _other_fg_manager = create(:admin, :manager, :with_access, resource: other_facility_group)

          facility = create(:facility, facility_group: facility_group)
          facility_manager = create(:admin, :manager, :with_access, resource: facility)
          _unsubscribed_facility_manager = create(:admin, :manager, :with_access, resource: facility, receive_approval_notifications: false)
          other_facility = create(:facility, facility_group: other_facility_group)
          _other_facility_manager = create(:admin, :manager, :with_access, resource: other_facility)

          user = create(:user, :sync_requested, organization: organization, registration_facility: facility)
          _other_user = create(:user, :sync_requested, organization: other_organization, registration_facility: other_facility)

          mail = described_class.registration_approval_email(user_id: user.id)

          expect(mail.subject).to eq("New Registration: User #{user.full_name} is requesting access to #{organization.name} facilities.")
          expect(mail.from).to eq(["help@simple.org"])
          expect(mail.to).to contain_exactly(facility_manager.email, fg_manager.email)
          expect(mail.cc).to contain_exactly(org_manager.email)
          expect(mail.bcc).to include(new_power_user.email)
          expect(mail.body).to include("New User Registered")
          expect(mail.body).to include("/admin/users/#{user.id}")
        end
      end
    end

    describe "reset_password_approval_email" do
      it "sends the password reset approval email" do
        new_power_user = create(:admin, :power_user)

        organization = create(:organization)
        org_manager = create(:admin, :manager, :with_access, resource: organization)
        _unsubscribed_org_manager = create(:admin, :manager, :with_access, resource: organization, receive_approval_notifications: false)
        other_organization = create(:organization)
        _other_org_manager = create(:admin, :manager, :with_access, resource: other_organization)

        facility_group = create(:facility_group, organization: organization)
        fg_manager = create(:admin, :manager, :with_access, resource: facility_group)
        _unsubscribed_fg_manager = create(:admin, :manager, :with_access, resource: facility_group, receive_approval_notifications: false)
        other_facility_group = create(:facility_group, organization: other_organization)
        _other_fg_manager = create(:admin, :manager, :with_access, resource: other_facility_group)

        facility = create(:facility, facility_group: facility_group)
        facility_manager = create(:admin, :manager, :with_access, resource: facility)
        _unsubscribed_facility_manager = create(:admin, :manager, :with_access, resource: facility, receive_approval_notifications: false)
        other_facility = create(:facility, facility_group: other_facility_group)
        _other_facility_manager = create(:admin, :manager, :with_access, resource: other_facility)

        user = create(:user, :sync_requested, organization: organization, registration_facility: facility)
        _other_user = create(:user, :sync_requested, organization: other_organization, registration_facility: other_facility)

        mail = described_class.reset_password_approval_email(user_id: user.id)

        expect(mail.subject).to eq("PIN Reset: User #{user.full_name} is requesting access.")
        expect(mail.from).to eq(["help@simple.org"])
        expect(mail.to).to contain_exactly(facility_manager.email, fg_manager.email)
        expect(mail.cc).to contain_exactly(org_manager.email)
        expect(mail.bcc).to include(new_power_user.email)
        expect(mail.body).to include("User has reset PIN.")
        expect(mail.body).to include("/admin/users/#{user.id}")
      end
    end
  end
end
