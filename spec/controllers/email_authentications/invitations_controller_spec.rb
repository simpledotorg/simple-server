require 'rails_helper'

RSpec.describe EmailAuthentications::InvitationsController, type: :controller do
  before do
    @request.env['devise.mapping'] = Devise.mappings[:email_authentication]
    admin = create(:admin, :owner)
    sign_in(admin.email_authentication)
  end

  describe '#new' do
    it 'returns a success response' do
      get :new, params: {}
      expect(response).to be_success
    end
  end

  describe '#create' do
    let(:organization) { create(:organization) }
    let(:facility_group) { create(:facility_group, organization: organization) }
    let(:facility) { create(:facility, facility_group: facility_group) }

    let(:full_name) { Faker::Name.name }
    let(:email) { Faker::Internet.email }
    let(:role) { 'Test User Role' }
    let(:params) do
      { full_name: full_name,
        email: email,
        role: role,
        organization_id: organization.id }
    end

    let(:permissions) do
      [{ permission_slug: :manage_organizations },
       { permission_slug: :manage_facility_groups,
         resource_type: 'Organization',
         resource_id: organization.id },
       { permission_slug: :manage_facilities,
         resource_type: 'FacilityGroup',
         resource_id: facility_group.id }]
    end

    context 'invitation params are valid' do
      it 'creates an email authentication for invited email' do
        expect do
          post :create, params: params
        end.to change(EmailAuthentication, :count).by(1)

        expect(EmailAuthentication.find_by(email: email)).to be_present
      end

      it 'creates a user record for the invited admin' do
        expect do
          post :create, params: params
        end.to change(User, :count).by(1)

        expect(User.find_by(full_name: full_name)).to be_present
      end

      it 'sends an email to the invited admin' do
        post :create, params: params
        invitation_email = ActionMailer::Base.deliveries.last
        expect(invitation_email.to).to include(email)
      end

      it 'assigns the selected permissions to the user' do
        expect do
          post :create, params: params.merge(permissions: permissions)
        end.to change(UserPermission, :count).by(permissions.length)

        user = EmailAuthentication.find_by(email: email).user
        expect(user.user_permissions.count).to eq(3)
      end
    end

    context 'invitation params are not valid' do
      it 'responds with bad request if full name is not present' do
        post :create, params: params.except(:full_name)

        expect(response).to be_bad_request
        expect(JSON(response.body)).to eq('errors' => ["Full name can't be blank"])
      end

      it 'responds with bad request if role is not present' do
        post :create, params: params.except(:role)

        expect(response).to be_bad_request
        expect(JSON(response.body)).to eq('errors' => ["Role can't be blank"])
      end

      it 'responds with bad request if email is not present' do
        post :create, params: params.except(:email)

        expect(response).to be_bad_request
        expect(JSON(response.body)).to eq('errors' => ["Email can't be blank"])
      end

      it 'responds with bad request if email is invalid' do
        post :create, params: params.merge(email: 'invalid email')

        expect(response).to be_bad_request
        expect(JSON(response.body)).to eq('errors' => ['Email is invalid'])
      end

      it 'responds with bad request email already exists' do
        EmailAuthentication.create!(email: email, password: generate(:strong_password))
        post :create, params: params

        expect(response).to be_bad_request
        expect(JSON(response.body)).to eq('errors' => ['Email has already been taken'])
      end

      it 'does not send an invitation email if the email is already taken' do
        EmailAuthentication.create!(email: email, password: generate(:strong_password))
        expect do
          post :create, params: params
        end.not_to change(ActionMailer::Base.deliveries, :count)
      end

      it 'does not send an invitation email params are invalid' do
        EmailAuthentication.create!(email: email, password: generate(:strong_password))
        expect do
          post :create, params: params.except(:full_name)
        end.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end
end
