require "rails_helper"

# Since Rate limiting is a controller middleware concern, we mark this test as a "controller"
describe "RateLimiter", type: :controller do
  include Rack::Test::Methods

  def app
    Rails.application
  end

  around(:example) do |example|
    Rails.cache.clear
    Rack::Attack.reset!
    example.run
    Rails.cache.clear
  end

  def stub_request_ip(host_id)
    allow_any_instance_of(Rack::Request).to receive(:ip).and_return("127.0.0.#{host_id}")
  end

  describe "throttle authentication APIs" do
    context "admin logins by IP address" do
      let(:limit) { 5 }
      let(:email) { "admin@admin" }
      let(:password) { "admin4815162342" }
      let(:admin) { create(:admin, email: email, password: password) }
      let(:login_params) {
        {
          email_authentications: {
            email: email,
            password: password
          }
        }
      }

      before(:each, type: :controller) do
        @request.remote_addr = "127.0.0.1"
      end

      context "number of requests is lower than the limit" do
        it "does not change the request status" do
          limit.times do
            post "/email_authentications/sign_in", login_params

            expect(last_response.status).to_not eq(429)
          end
        end
      end

      context "number of requests is higher than the limit" do
        it "changes the request status to 429" do
          (limit * 2).times do |i|
            post "/email_authentications/sign_in", login_params

            if i > limit
              expect(last_response.status).to eq(429)
              expect(last_response.body).to eq("Too many requests. Please wait and try again later.\n")
            end
          end
        end
      end
    end

    context "admin password modifications by IP address" do
      let(:limit) { 5 }
      let(:email) { "admin@admin" }
      let(:password) { "admin4815162342" }
      let(:admin) { create(:admin, email: email, password: password) }
      let(:login_params) {
        {
          email_authentications: {
            email: email,
            password: password
          }
        }
      }

      before(:each, type: :controller) do
        @request.remote_addr = "127.0.0.1"
      end

      context "reset password" do
        context "number of requests is lower than the limit" do
          it "does not change the request status for a POST" do
            limit.times do
              post "/email_authentications/password"

              expect(last_response.status).to_not eq(429)
            end
          end

          it "does not change the request status for a PUT" do
            limit.times do
              put "/email_authentications/password"

              expect(last_response.status).to_not eq(429)
            end
          end
        end

        context "number of requests is higher than the limit" do
          it "changes the request status to 429 for a POST" do
            (limit * 2).times do |i|
              post "/email_authentications/password"

              if i > limit
                expect(last_response.status).to eq(429)
                expect(last_response.body).to eq("Too many requests. Please wait and try again later.\n")
              end
            end
          end

          it "changes the request status to 429 for a PUT" do
            (limit * 2).times do |i|
              put "/email_authentications/password"

              if i > limit
                expect(last_response.status).to eq(429)
                expect(last_response.body).to eq("Too many requests. Please wait and try again later.\n")
              end
            end
          end
        end
      end

      context "edit page" do
        let(:token) { build(:email_authentication).send_reset_password_instructions }

        context "number of requests is lower than the limit" do
          it "does not change the request status" do
            limit.times do
              get "/email_authentications/password/edit", reset_password_token: token

              expect(last_response.status).to_not eq(429)
            end
          end
        end

        context "number of requests is higher than the limit" do
          it "changes the request status to 429" do
            (limit * 2).times do |i|
              get "/email_authentications/password/edit", reset_password_token: token

              if i > limit
                expect(last_response.status).to eq(429)
                expect(last_response.body).to eq("Too many requests. Please wait and try again later.\n")
              end
            end
          end
        end
      end
    end

    context "user phone number lookups by IP address" do
      let(:limit) { 5 }
      before(:each, type: :controller) do
        @request.remote_addr = "127.0.0.1"
      end

      it "does not change the request status when the number of requests is lower than the limit" do
        limit.times do
          post "/api/v4/users/find", phone_number: "1234567890"
          expect(last_response.status).to eq(404)
        end
      end

      it "returns 429 when the number of requests is higher than the limit" do
        (limit * 2).times do |i|
          post "/api/v4/users/find", phone_number: "1234567890"
          if i > limit
            expect(i > limit).to eq(true)
            expect(last_response.status).to eq(429)
            expect(last_response.body).to eq("Too many requests. Please wait and try again later.\n")
          end
        end
      end
    end

    context "user activate / resending OTPs" do
      before(:each, type: :controller) do
        @request.remote_addr = "127.0.0.1"
        allow(RequestOtpSmsJob).to receive_message_chain("set.perform_later")
      end

      context "by IP address" do
        let(:limit) { 5 }

        it "returns 429 when over the limit" do
          limit.times do
            post "/api/v4/users/activate", {user: {id: SecureRandom.uuid, password: "1234"}}
            expect(last_response.status).to eq(401)
          end

          post "/api/v4/users/activate", {user: {id: SecureRandom.uuid, password: "1234"}}
          expect(last_response.status).to eq(429)
          expect(last_response.body).to eq("Too many requests. Please wait and try again later.\n")
        end

        it "does not rate limit across IP addresses" do
          (limit * 2).times do |i|
            stub_request_ip(i)
            post "/api/v4/users/activate", {user: {id: SecureRandom.uuid, password: "1234"}}
            if i > limit
              expect(i > limit).to eq(true)
              expect(last_response.status).to eq(401)
            end
          end
        end

        it "does not rate limit in non production environments" do
          user = create(:user, password: "1234")
          stub_const("SIMPLE_SERVER_ENV", "sandbox")

          (limit * 2).times do |i|
            post "/api/v4/users/activate", {user: {id: user.id, password: "1234"}}
            if i > limit
              expect(i > limit).to eq(true)
              expect(last_response.status).to eq(200)
            end
          end
        end
      end

      context "by user ID" do
        let(:limit) { 5 }

        it "returns 200 when under limit, and 429 when over the limit" do
          user = create(:user, password: "1234")

          limit.times do |i|
            stub_request_ip(i)
            post "/api/v4/users/activate", {user: {id: user.id, password: "1234"}}
            expect(last_response.status).to eq(200)
          end

          stub_request_ip(limit + 1)
          post "/api/v4/users/activate", {user: {id: user.id, password: "1234"}}
          expect(last_response.status).to eq(429)
          expect(last_response.body).to eq("Too many requests. Please wait and try again later.\n")
        end

        it "does not rate limit across user ids" do
          (limit * 2).times do |i|
            stub_request_ip(i)
            post "/api/v4/users/activate", {user: {id: SecureRandom.uuid, password: "1234"}}
            if i > limit
              expect(i > limit).to eq(true)
              expect(last_response.status).to eq(401)
            end
          end
        end

        it "doesn't return a 429 when the params doesn't have a user id" do
          bad_params = [nil, {user: {}}]

          bad_params.each do |bad_param|
            (limit * 2).times do |i|
              stub_request_ip(i)
              post "/api/v4/users/activate", bad_param
              if i > limit
                expect(i > limit).to eq(true)
                expect(last_response.status).to eq(400)
              end
            end
          end
        end

        it "does not rate limit in non production environments" do
          stub_const("SIMPLE_SERVER_ENV", "sandbox")
          user = create(:user, password: "1234")

          (limit * 2).times do |i|
            post "/api/v4/users/activate", {user: {id: user.id, password: "1234"}}
            stub_request_ip(i)

            if i > limit
              expect(i > limit).to eq(true)
              expect(last_response.status).to eq(200)
            end
          end
        end
      end
    end
  end

  describe "throttle patient lookup API" do
    def setup_patient_lookup_request
      patient = create(:patient)
      user = patient.registration_user
      facility = patient.registration_facility
      {
        headers: {
          "HTTP_X_USER_ID" => user.id,
          "HTTP_X_FACILITY_ID" => facility.id,
          "HTTP_AUTHORIZATION" => "Bearer #{user.access_token}",
          "Accept" => "application/json"
        },
        identifier: patient.business_identifiers.first.identifier
      }
    end

    before(:each) do
      @request.remote_addr = "127.0.0.1"
    end

    it "returns patients when under rate limit, and 429 when over the limit" do
      limit = 5
      identifier, headers = setup_patient_lookup_request.values_at(:identifier, :headers)

      limit.times do
        post "/api/v4/patients/lookup", {identifier: identifier}, headers
        expect(last_response.status).to eq(200)
      end

      post "/api/v4/patients/lookup", {identifier: identifier}, headers
      expect(last_response.status).to eq(429)
    end
  end
end
