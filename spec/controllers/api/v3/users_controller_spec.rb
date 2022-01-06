# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V3::UsersController, type: :controller do
  require "sidekiq/testing"

  let(:facility) { create(:facility) }
  let!(:owner) { create(:admin, :power_user) }
  let!(:supervisor) { create(:admin, :manager, :with_access, resource: facility.facility_group) }
  let!(:organization_owner) { create(:admin, :manager, :with_access, resource: facility.organization) }

  describe "#register" do
    describe "registration payload is invalid" do
      let(:request_params) { {user: FactoryBot.attributes_for(:user).slice(:full_name, :phone_number)} }
      it "responds with 400" do
        post :register, params: request_params

        expect(response.status).to eq(400)
      end
    end

    describe "registration payload is valid" do
      let(:user_params) { register_user_request_params(registration_facility_id: facility.id) }
      let(:phone_number) { user_params[:phone_number] }
      let(:password_digest) { user_params[:password_digest] }

      it "creates a user, and responds with the created user object and their access token" do
        post :register, params: {user: user_params}
        parsed_response = JSON(response.body)

        created_user = User.find_by(full_name: user_params[:full_name])
        expect(response.status).to eq(200)
        expect(created_user).to be_present
        expect(created_user.phone_number_authentication).to be_present
        expect(created_user.phone_number_authentication.phone_number).to eq(user_params[:phone_number])

        expect(parsed_response["user"].except("created_at",
          "updated_at",
          "facility_ids").with_int_timestamps)
          .to eq(created_user.attributes
                   .except(
                     "role",
                     "organization_id",
                     "device_updated_at",
                     "device_created_at",
                     "created_at",
                     "updated_at"
                   )
                   .merge("registration_facility_id" => facility.id, "phone_number" => phone_number, "password_digest" => password_digest)
                   .as_json
                   .with_int_timestamps)

        expect(parsed_response["user"]["registration_facility_id"]).to eq(facility.id)
        expect(parsed_response["access_token"]).to eq(created_user.access_token)
      end

      it "sets the user status to requested" do
        post :register, params: {user: user_params}
        created_user = User.find_by(full_name: user_params[:full_name])
        expect(created_user.sync_approval_status).to eq(User.sync_approval_statuses[:requested])
        expect(created_user.sync_approval_status_reason).to eq(I18n.t("registration"))
      end

      it "sets the user status to approved if auto_approve_users feature is enabled" do
        Flipper.enable(:auto_approve_users)

        post :register, params: {user: user_params}
        created_user = User.find_by(full_name: user_params[:full_name])
        expect(created_user.sync_approval_status).to eq(User.sync_approval_statuses[:allowed])
      end

      context "registration_approval_email in a production environment" do
        before { stub_const("SIMPLE_SERVER_ENV", "production") }

        it "sends an email to a list of owners and supervisors" do
          Sidekiq::Testing.inline! do
            post :register, params: {user: user_params}
          end
          approval_email = ActionMailer::Base.deliveries.last
          expect(approval_email.to).to include(supervisor.email)
          expect(approval_email.cc).to include(organization_owner.email)
          expect(approval_email.body.to_s).to match(Regexp.quote(user_params[:phone_number]))
        end

        it "sends an email with owners in the bcc list" do
          Sidekiq::Testing.inline! do
            post :register, params: {user: user_params}
          end
          approval_email = ActionMailer::Base.deliveries.last
          expect(approval_email.bcc).to include(owner.email)
        end

        it "sends an approval email with list of accessible facilities" do
          Sidekiq::Testing.inline! do
            post :register, params: {user: user_params}
          end
          approval_email = ActionMailer::Base.deliveries.last
          facility.facility_group.facilities.each do |facility|
            expect(approval_email.body.to_s).to match(Regexp.quote(facility.name))
          end
        end

        it "sends an email using sidekiq" do
          Sidekiq::Testing.fake! do
            expect {
              post :register, params: {user: user_params}
            }.to change(Sidekiq::Extensions::DelayedMailer.jobs, :size).by(1)
          end
        end
      end
    end
  end

  describe "#find" do
    let(:phone_number) { Faker::PhoneNumber.phone_number }
    let(:facility) { create(:facility) }
    let!(:db_users) { create_list(:user, 10, registration_facility: facility) }
    let!(:user) { create(:user, phone_number: phone_number, registration_facility: facility) }

    it "lists the users with the given phone number" do
      get :find, params: {phone_number: phone_number}
      expect(response.status).to eq(200)
      expect(JSON(response.body).with_int_timestamps)
        .to eq(Api::V3::UserTransformer.to_response(user).with_int_timestamps)
    end

    it "lists the users with the given id" do
      get :find, params: {id: user.id}
      expect(response.status).to eq(200)
      expect(JSON(response.body).with_int_timestamps)
        .to eq(Api::V3::UserTransformer.to_response(user).with_int_timestamps)
    end

    it "returns 404 when user is not found" do
      get :find, params: {phone_number: Faker::PhoneNumber.phone_number}
      expect(response.status).to eq(404)
    end
  end

  describe "#request_otp" do
    let(:user) { create(:user) }

    it "returns 404 if the user with id doesn't exist" do
      post :request_otp, params: {id: SecureRandom.uuid}

      expect(response.status).to eq(404)
    end

    it "updates the user otp and sends an sms to the user's phone number with the new otp" do
      existing_otp = user.otp

      expect(RequestOtpSmsJob).to receive_message_chain("set.perform_later").with(user)

      post :request_otp, params: {id: user.id}
      user.reload
      expect(user.otp).not_to eq(existing_otp)
    end

    it "uses a sensible default when the OTP delay is not configured" do
      ENV["USER_OTP_SMS_DELAY_IN_SECONDS"] = nil

      existing_otp = user.otp

      expect(RequestOtpSmsJob).to receive_message_chain("set.perform_later").with(user)

      post :request_otp, params: {id: user.id}
      user.reload
      expect(user.otp).not_to eq(existing_otp)
    end

    it "does not send an OTP if fixed_otp is enabled" do
      Flipper.enable(:fixed_otp)

      expect(RequestOtpSmsJob).not_to receive(:set)

      post :request_otp, params: {id: user.id}
    end
  end

  describe "#reset_password" do
    let(:facility_group) { create(:facility_group) }
    let(:facility) { create(:facility, facility_group: facility_group) }
    let(:user) { create(:user, registration_facility: facility, organization: facility.organization) }

    before(:each) do
      request.env["HTTP_X_USER_ID"] = user.id
      request.env["HTTP_X_FACILITY_ID"] = facility.id
      request.env["HTTP_AUTHORIZATION"] = "Bearer #{user.access_token}"
    end

    it "Resets the password for the given user with the given digest" do
      new_password_digest = BCrypt::Password.create("1234").to_s
      post :reset_password, params: {id: user.id, password_digest: new_password_digest}
      user.reload
      expect(response.status).to eq(200)
      expect(user.password_digest).to eq(new_password_digest)
      expect(user.sync_approval_status).to eq("requested")
      expect(user.sync_approval_status_reason).to eq(I18n.t("reset_password"))
    end

    it "leaves the user approved if auto approve is enabled" do
      Flipper.enable(:auto_approve_users)

      new_password_digest = BCrypt::Password.create("1234").to_s
      post :reset_password, params: {id: user.id, password_digest: new_password_digest}
      user.reload
      expect(response.status).to eq(200)
      expect(user.password_digest).to eq(new_password_digest)
      expect(user.sync_approval_status).to eq("allowed")
    end

    it "Returns 401 if the user is not authorized" do
      request.env["HTTP_AUTHORIZATION"] = "an invalid access token"
      post :reset_password, params: {id: user.id}
      expect(response.status).to eq(401)
    end

    it "Returns 401 if the user is not present" do
      request.env["HTTP_X_USER_ID"] = SecureRandom.uuid
      post :reset_password, params: {id: SecureRandom.uuid}
      expect(response.status).to eq(401)
    end

    it "Sends an email to a list of owners and supervisors" do
      Sidekiq::Testing.inline! do
        post :reset_password, params: {id: user.id, password_digest: BCrypt::Password.create("1234").to_s}
      end
      approval_email = ActionMailer::Base.deliveries.last
      expect(approval_email).to be_present
      expect(approval_email.to).to include(supervisor.email)
      expect(approval_email.cc).to include(organization_owner.email)
      expect(approval_email.body.to_s).to match(Regexp.quote(user.phone_number))
      expect(approval_email.body.to_s).to match("reset")
    end

    it "does not send an email if users are auto approved" do
      Flipper.enable(:auto_approve_users)

      Sidekiq::Testing.inline! do
        post :reset_password, params: {id: user.id, password_digest: BCrypt::Password.create("1234").to_s}
      end
      approval_email = ActionMailer::Base.deliveries.last

      expect(approval_email).to be_nil
    end

    it "sends an email using sidekiq" do
      Sidekiq::Testing.fake! do
        expect {
          post :reset_password, params: {id: user.id, password_digest: BCrypt::Password.create("1234").to_s}
        }.to change(Sidekiq::Extensions::DelayedMailer.jobs, :size).by(1)
      end
    end
  end
end
