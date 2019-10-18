require 'rails_helper'

RSpec.describe EmailAuthentications::InvitationsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:email_authentication]
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

    it 'creates an email authentication for invited email' do
      expect {
        post :create, params: params
      }.to change(EmailAuthentication, :count).by(1)

      expect(EmailAuthentication.find_by(email: email)).to be_present
    end

    it 'creates a user record for the invited admin' do
      expect {
        post :create, params: params
      }.to change(User, :count).by(1)

      expect(User.find_by(full_name: full_name)).to be_present
    end

    it 'sends an email to the invited admin' do
      post :create, params: params
      invitation_email = ActionMailer::Base.deliveries.last
      expect(invitation_email.to).to include(email)
    end

    it 'assigns the selected permissions to the user' do
      expect {
        post :create, params: params.merge(permissions: permissions)
      }.to change(UserPermission, :count).by(permissions.length)

      user = EmailAuthentication.find_by(email: email).user
      expect(user.user_permissions.count).to eq(3)
    end
  end
end