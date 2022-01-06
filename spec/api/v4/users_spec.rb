# frozen_string_literal: true

require "swagger_helper"

describe "Users v4 API", swagger_doc: "v4/swagger.json" do
  path "/users/find" do
    post "Find a existing user" do
      tags "User"
      parameter name: :phone_number, in: :body, schema: Api::V4::Schema.user_find_request

      let(:known_phone_number) { Faker::PhoneNumber.phone_number }
      let!(:user) { create(:user, phone_number: known_phone_number) }
      let(:id) { user.id }

      response "200", "user is found" do
        schema Api::V4::Schema.user_find_response
        let(:phone_number) { {phone_number: known_phone_number} }
        let(:id) { user.id }
        run_test!
      end

      response "404", "user is not found" do
        let(:id) { SecureRandom.uuid }
        let(:phone_number) { {phone_number: Faker::PhoneNumber.phone_number} }

        run_test!
      end
    end
  end

  path "/users/activate" do
    post "Authenticate user, request OTP, and get user information" do
      tags "User"
      parameter name: :user, in: :body, schema: Api::V4::Schema.user_activate_request

      before :each do
        allow(RequestOtpSmsJob).to receive(:perform_later).with(instance_of(User))
      end

      response "200", "user is authenticated" do
        let(:db_user) { create(:user, password: "1234") }
        let(:user) do
          {user: {id: db_user.id,
                  password: "1234"}}
        end

        schema Api::V4::Schema.user_activate_response
        run_test!
      end

      response "401", "incorrect user id or password, authentication failed" do
        let(:db_user) { create(:user) }
        let(:user) do
          {user: {id: db_user.id,
                  password: "wrong_password"}}
        end

        schema Api::V4::Schema.user_activate_error
        run_test!
      end

      response "200", "user otp is reset and new otp is sent as an sms" do
        let(:db_user) { create(:user, password: "1234") }
        let(:user) do
          {user: {id: db_user.id,
                  password: "1234"}}
        end

        run_test!
      end
    end
  end

  path "/users/me/" do
    parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid, required: true
    parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid, required: true

    get "Fetch user information" do
      tags "User"
      security [access_token: [], user_id: [], facility_id: []]
      let(:facility) { create(:facility) }
      let(:user) { create(:user, registration_facility: facility) }
      let(:HTTP_X_USER_ID) { user.id }
      let(:HTTP_X_FACILITY_ID) { facility.id }
      let(:Authorization) { "Bearer #{user.access_token}" }

      response "200", "returns user information" do
        schema Api::V4::Schema.user_me_response
        run_test!
      end

      response "401", "authentication failed" do
        let(:Authorization) { "Bearer 'random string'" }
        run_test!
      end
    end
  end
end
