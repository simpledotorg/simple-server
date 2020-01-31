require 'rails_helper'

RSpec.describe AdminsController, type: :controller do
  let(:user) { create(:admin) }

  before do
    sign_in(user.email_authentication)
  end

  describe '#index' do
    context 'user does not have permission to manage admins' do
      it 'redirects the user' do
        get :index
        expect(response).to be_redirect
      end
    end

    context 'user has permission to manage admins' do
      before { user.user_permissions.create(permission_slug: :manage_admins) }

      it 'responds with ok' do
        get :index
        expect(response).to be_ok
      end
    end
  end

  describe '#show' do
    let(:existing_admin) { create(:admin) }
    context 'user does not have permission to manage admins' do
      it 'redirects the user' do
        get :show, params: { id: existing_admin.id }

        expect(response).to be_redirect
      end
    end

    context 'user has permission to manage admins' do
      before { user.user_permissions.create(permission_slug: :manage_admins) }
      it 'responsd with ok' do
        get :show, params: { id: existing_admin.id }

        expect(response).to be_ok
      end
    end
  end

  describe '#edit' do
    let(:existing_admin) { create(:admin) }
    context 'user does not have permission to manage admins' do
      it 'redirects the user' do
        get :edit, params: { id: existing_admin.id }

        expect(response).to be_redirect
      end
    end

    context 'user has permission to manage admins' do
      before { user.user_permissions.create(permission_slug: :manage_admins) }
      it 'responsd with ok' do
        get :edit, params: { id: existing_admin.id }

        expect(response).to be_ok
      end
    end
  end

  describe '#destroy' do
    let(:existing_admin) { create(:admin) }
    context 'user does not have permission to manage admins' do
      it 'redirects the user' do
        delete :destroy, params: { id: existing_admin.id }

        expect(response).to be_redirect
      end
    end

    context 'user has permission to manage admins' do
      before { user.user_permissions.create(permission_slug: :manage_admins) }
      it 'responsd with ok' do
        delete :destroy, params: { id: existing_admin.id }

        expect(response).to be_redirect
      end
    end
  end

  describe '#update' do
    let(:organization) { create(:organization) }
    let(:facility_group) { create(:facility_group, organization: organization) }

    let(:full_name) { Faker::Name.name }
    let(:email) { Faker::Internet.email }
    let(:role) { 'Test User Role' }

    let(:params) do
      { full_name: full_name,
        email: email,
        role: role,
        organization_id: organization.id }
    end

    let(:permission_params) do
      [{ permission_slug: :manage_organizations },
       { permission_slug: :manage_facility_groups,
         resource_type: 'Organization',
         resource_id: organization.id },
       { permission_slug: :manage_facilities,
         resource_type: 'FacilityGroup',
         resource_id: facility_group.id }]
    end

    let(:existing_admin) { create(:admin, params) }

    context 'user does not have permission to manage admins' do
      it 'redirects the user' do
        put :update, params: params.merge(id: existing_admin.id)

        expect(response).to be_redirect
      end
    end

    context 'user has permission to manage admins' do
      before { user.user_permissions.create(permission_slug: :manage_admins) }

      context 'update params are valid' do
        it 'allows updating user full name' do
          new_name = Faker::Name.name
          put :update, params: params.merge(id: existing_admin.id, full_name: new_name)

          existing_admin.reload

          expect(response).to be_ok
          expect(existing_admin.full_name).to eq(new_name)
        end

        it 'allows updating user role' do
          new_role = 'New user role'
          put :update, params: params.merge(id: existing_admin.id, role: new_role)

          existing_admin.reload

          expect(response).to be_ok
          expect(existing_admin.role).to eq(new_role)
        end

        it 'does not allow updating user email' do
          new_email = Faker::Internet.email
          put :update, params: params.merge(id: existing_admin.id, email: new_email)

          existing_admin.reload

          expect(response).to be_ok
          expect(existing_admin.role).not_to eq(new_email)
        end

        it 'updates user permissions' do
          put :update, params: params.merge(id: existing_admin.id, permissions: permission_params)

          existing_admin.reload
          expect(existing_admin.user_permissions.pluck(:permission_slug))
            .to match_array(permission_params.map { |p| p[:permission_slug].to_s })
        end
      end

      context 'update params are invalid' do
        it 'responds with bad request if full name is missing' do
          put :update, params: params.merge(id: existing_admin.id, full_name: nil)

          expect(response).to be_bad_request
          expect(JSON(response.body)).to eq('errors' => ["Full name can't be blank"])
        end

        it 'responds with bad request if role is missing' do
          put :update, params: params.merge(id: existing_admin.id, role: nil)

          expect(response).to be_bad_request
          expect(JSON(response.body)).to eq('errors' => ["Role can't be blank"])
        end
      end
    end
  end
end
