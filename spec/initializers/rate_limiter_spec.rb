require "rails_helper"

# Since Rate limiting is a controller middleware concern, we mark this test as a "controller"
describe "RateLimiter", type: :controller do
  include Rack::Test::Methods

  def app
    Rails.application
  end

  around(:example) do |example|
    Rails.cache.clear
    example.run
    Rails.cache.clear
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
        context "number of requests is lower than the limit" do
          it "does not change the request status" do
            limit.times do
              get "/email_authentications/password/edit", reset_password_token: "zzSUazFCxzom5XzmGTNQ"

              expect(last_response.status).to_not eq(429)
            end
          end
        end

        context "number of requests is higher than the limit" do
          it "changes the request status to 429" do
            (limit * 2).times do |i|
              get "/email_authentications/password/edit", reset_password_token: "zzSUazFCxzom5XzmGTNQ"

              if i > limit
                expect(last_response.status).to eq(429)
                expect(last_response.body).to eq("Too many requests. Please wait and try again later.\n")
              end
            end
          end
        end
      end
    end
  end
end
