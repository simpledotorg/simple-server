require "rails_helper"

RSpec.describe EmailAuthentications::InvitationsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:email_authentication]
    admin = create(:admin, :owner)
    sign_in(admin.email_authentication)
    ActionMailer::Base.deliveries.clear
  end

  describe "#new" do
    it "returns a success response" do
      get :new, params: {}
      expect(response).to be_successful
    end
  end

  describe "#create" do
    context "legacy permissions" do
      let(:organization) { create(:organization) }
      let(:facility_group) { create(:facility_group, organization: organization) }
      let(:facility) { create(:facility, facility_group: facility_group) }

      let(:full_name) { Faker::Name.name }
      let(:email) { Faker::Internet.email }
      let(:role) { "Test User Role" }
      let(:params) do
        {full_name: full_name,
         email: email,
         role: role,
         organization_id: organization.id}
      end

      let(:permissions) do
        [{permission_slug: :manage_organizations},
          {permission_slug: :manage_facility_groups,
           resource_type: "Organization",
           resource_id: organization.id},
          {permission_slug: :manage_facilities,
           resource_type: "FacilityGroup",
           resource_id: facility_group.id}]
      end

      context "invitation params are valid" do
        it "creates an email authentication for invited email" do
          expect {
            post :create, params: params
          }.to change(EmailAuthentication, :count).by(1)

          expect(EmailAuthentication.find_by(email: email)).to be_present
        end

        it "creates a user record for the invited admin" do
          expect {
            post :create, params: params
          }.to change(User, :count).by(1)

          expect(User.find_by(full_name: full_name)).to be_present
        end

        it "sends an email to the invited admin" do
          post :create, params: params
          invitation_email = ActionMailer::Base.deliveries.last
          expect(invitation_email.to).to include(email)
        end

        it "assigns the selected permissions to the user" do
          expect {
            post :create, params: params.merge(permissions: permissions)
          }.to change(UserPermission, :count).by(permissions.length)

          user = EmailAuthentication.find_by(email: email).user
          expect(user.user_permissions.count).to eq(3)
        end
      end

      context "invitation params are not valid" do
        it "responds with bad request if full name is not present" do
          post :create, params: params.except(:full_name)

          expect(response).to be_bad_request
          expect(JSON(response.body)).to eq("errors" => ["Full name can't be blank"])
        end

        it "responds with bad request if role is not present" do
          post :create, params: params.except(:role)

          expect(response).to be_bad_request
          expect(JSON(response.body)).to eq("errors" => ["Role can't be blank"])
        end

        it "responds with bad request if email is not present" do
          post :create, params: params.except(:email)

          expect(response).to be_bad_request
          expect(JSON(response.body)).to eq("errors" => ["Email can't be blank"])
        end

        it "responds with bad request if email is invalid" do
          post :create, params: params.merge(email: "invalid email", password: generate(:strong_password))

          expect(response).to be_bad_request
          expect(JSON(response.body)).to eq("errors" => ["Email is invalid"])
        end

        it "responds with bad request email already exists" do
          EmailAuthentication.create!(email: email, password: generate(:strong_password))
          post :create, params: params

          expect(response).to be_bad_request
          expect(JSON(response.body)).to eq("errors" => ["Email has already been taken"])
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
            post :create, params: params.except(:full_name)
          }.not_to change(ActionMailer::Base.deliveries, :count)
        end
      end
    end

    context "new permissions" do
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
          organization_id: organization.id
        }
      }
      let(:selected_facility_ids) { facilities.map(&:id) }
      let(:request_params) { params.merge(facilities: selected_facility_ids) }

      before(:each) do
        enable_flag(:new_permissions_system_aug_2020, manager)
      end

      after(:each) do
        disable_flag(:new_permissions_system_aug_2020, manager)
      end

      context "validate params" do
        before(:each) do
          sign_in(manager.email_authentication)
        end

        context "create params are valid" do
          it "responds successfully" do
            post :create, params: request_params

            expect(response).to redirect_to(admins_url)
          end

          it "creates an email authentication for invited email" do
            expect {
              post :create, params: request_params
            }.to change(EmailAuthentication, :count).by(1)

            expect(EmailAuthentication.find_by(email: email)).to be_present
          end

          it "creates a user record for the invited admin" do
            expect {
              post :create, params: request_params
            }.to change(User, :count).by(1)

            new_user = User.find_by(full_name: full_name)
            expect(new_user.full_name).to eq(params[:full_name])
            expect(new_user.role).to eq(params[:role])
          end

          it "sends an email to the invited admin" do
            post :create, params: request_params

            invitation_email = ActionMailer::Base.deliveries.last
            expect(invitation_email.to).to include(email)
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
          expect(response).to redirect_to(admins_url)

          sign_out(manager.email_authentication)
        end

        it "allowed power_users to invite new admins" do
          enable_flag(:new_permissions_system_aug_2020, power_user)
          sign_in(power_user.email_authentication)

          post :create, params: request_params
          expect(response).to redirect_to(admins_url)

          disable_flag(:new_permissions_system_aug_2020, power_user)
        end
      end

      context "user cannot manage admins" do
        it "disallows non-managers from inviting admins" do
          managers = %w[manager power_user]
          non_managers = User.access_levels.except(*managers).keys

          non_managers.each do |access_level|
            non_manager = create(:admin, access_level.to_sym, :with_access, resource: organization)
            enable_flag(:new_permissions_system_aug_2020, non_manager)
            sign_in(non_manager.email_authentication)

            post :create, params: request_params
            expect(response).to redirect_to(root_path)

            disable_flag(:new_permissions_system_aug_2020, non_manager)
          end
        end
      end
    end
  end
end
