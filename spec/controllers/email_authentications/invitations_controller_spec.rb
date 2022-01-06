# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailAuthentications::InvitationsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:email_authentication]
    admin = create(:admin, :power_user)
    sign_in(admin.email_authentication)
    ActionMailer::Base.deliveries.clear
  end

  describe "#new" do
    it "returns a success response" do
      create(:facility)
      get :new, params: {}
      expect(response).to be_successful
    end
  end

  describe "#create" do
    let(:organization) { create(:organization) }
    let(:facility_group) { create(:facility_group, organization: organization) }
    let(:facilities) { create_list(:facility, 2, facility_group: facility_group) }
    let(:manager) { create(:admin, :manager, :with_access, resource: organization) }
    let(:power_user) { create(:admin, :power_user) }
    let(:full_name) { Faker::Name.name }
    let(:email) { Faker::Internet.email }
    let(:job_title) { "Title" }
    let(:params) {
      {
        full_name: full_name,
        email: email,
        role: job_title,
        access_level: :manager,
        receive_approval_notifications: false,
        organization_id: organization.id
      }
    }
    let(:selected_facility_ids) { facilities.map(&:id) }
    let(:request_params) { params.merge(facilities: selected_facility_ids) }

    context "validate params" do
      before(:each) do
        sign_in(manager.email_authentication)
      end

      context "create params are valid" do
        it "responds successfully" do
          post :create, params: request_params

          expect(response).to redirect_to(admins_url), -> { {status: response.status, body: response.body, flash: flash} }
        end

        it "creates an email authentication for invited email" do
          expect {
            post :create, params: request_params
          }.to change(EmailAuthentication, :count).by(1), -> { {status: response.status, body: response.body, flash: flash} }

          expect(EmailAuthentication.find_by(email: email)).to be_present
        end

        it "creates a user record for the invited admin" do
          expect {
            post :create, params: request_params
          }.to change(User, :count).by(1), -> { {status: response.status, body: response.body, flash: flash} }

          new_user = User.find_by(full_name: full_name)
          expect(new_user.full_name).to eq(params[:full_name])
          expect(new_user.role).to eq(params[:role])
          expect(new_user.receive_approval_notifications).to eq(params[:receive_approval_notifications])
        end

        it "sends an email to the invited admin" do
          post :create, params: request_params

          invitation_email = ActionMailer::Base.deliveries.last
          expect(invitation_email.to).to include(email), -> { {status: response.status, body: response.body, flash: flash} }
        end
      end

      context "create params are invalid" do
        [:full_name, :role, :email].each do |param|
          it "responds with bad request if #{param} is not present" do
            post :create, params: request_params.except(param)

            expect(response).to be_bad_request
          end
        end

        it "responds with bad request if email is invalid" do
          post :create, params: request_params.merge(email: "invalid email", password: generate(:strong_password))

          expect(response).to be_bad_request
        end

        it "responds with bad request email already exists" do
          EmailAuthentication.create!(email: email, password: generate(:strong_password))
          post :create, params: params

          expect(response).to be_bad_request
        end

        it "does not send an invitation email if the email is already taken" do
          EmailAuthentication.create!(email: email, password: generate(:strong_password))
          expect {
            post :create, params: params
          }.not_to change(ActionMailer::Base.deliveries, :count)
        end

        it "does not send an invitation email params are invalid" do
          EmailAuthentication.create!(email: email, password: generate(:strong_password))
          expect {
            post :create, params: request_params.except(:full_name)
          }.not_to change(ActionMailer::Base.deliveries, :count)
        end

        it "responds with bad request if selected_facilities are missing for non power users" do
          post :create, params: request_params.merge(facilities: nil)

          expect(response).to be_bad_request
        end
      end
    end

    context "user can manage admins" do
      it "allows managers to invite new admins" do
        sign_in(manager.email_authentication)

        post :create, params: request_params
        expect(response).to redirect_to(admins_url), -> { {status: response.status, body: response.body, flash: flash} }

        sign_out(manager.email_authentication)
      end

      it "allowed power_users to invite new admins" do
        sign_in(power_user.email_authentication)

        post :create, params: request_params
        expect(response).to redirect_to(admins_url), -> { {status: response.status, body: response.body, flash: flash} }
      end
    end

    context "user cannot manage admins" do
      it "disallows non-managers from inviting admins" do
        managers = %w[manager power_user]
        non_managers = User.access_levels.except(*managers).keys

        non_managers.each do |access_level|
          non_manager = create(:admin, access_level.to_sym, :with_access, resource: organization)
          sign_in(non_manager.email_authentication)

          post :create, params: request_params
          expect(response).to redirect_to(root_path), -> { {status: response.status, body: response.body, flash: flash} }
        end
      end
    end
  end
end
