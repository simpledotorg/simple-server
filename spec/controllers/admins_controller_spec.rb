require "rails_helper"

RSpec.describe AdminsController, type: :controller do
  let(:user) { create(:admin) }

  before do
    sign_in(user.email_authentication)
  end

  describe "#index" do
    context "user does not have permission to manage admins" do
      it "redirects the user" do
        get :index
        expect(response).to be_redirect
      end
    end

    context "user has permission to manage admins" do
      before { user.user_permissions.create(permission_slug: :manage_admins) }

      it "responds with ok" do
        get :index
        expect(response).to be_ok
      end

      it "populates a subset of filtered admins by search term" do
        admin1 = create(:admin, full_name: "Doctor Jack")
        _admin = create(:admin, full_name: "Jack")

        get :index, params: {search_query: "Doctor"}
        expect(assigns(:admins)).to match_array(admin1)
        expect(response).to be_successful
      end

      it "fetches no admins for search term with no matches" do
        create(:admin, full_name: "Doctor Jack")
        create(:admin, full_name: "Jack")

        get :index, params: {search_query: "Shephard"}
        expect(assigns(:admins)).to match_array([])
        expect(response).to be_successful
      end
    end
  end

  describe "#show" do
    let(:existing_admin) { create(:admin) }
    context "user does not have permission to manage admins" do
      it "redirects the user" do
        get :show, params: {id: existing_admin.id}

        expect(response).to be_redirect
      end
    end

    context "user has permission to manage admins" do
      before { user.user_permissions.create(permission_slug: :manage_admins) }
      it "responsd with ok" do
        get :show, params: {id: existing_admin.id}

        expect(response).to be_ok
      end
    end
  end

  describe "#edit" do
    let(:existing_admin) { create(:admin) }
    context "user does not have permission to manage admins" do
      it "redirects the user" do
        get :edit, params: {id: existing_admin.id}

        expect(response).to be_redirect
      end
    end

    context "user has permission to manage admins" do
      before { user.user_permissions.create(permission_slug: :manage_admins) }
      it "responsd with ok" do
        get :edit, params: {id: existing_admin.id}

        expect(response).to be_ok
      end
    end
  end

  describe "#destroy" do
    let(:existing_admin) { create(:admin) }
    context "user does not have permission to manage admins" do
      it "redirects the user" do
        delete :destroy, params: {id: existing_admin.id}

        expect(response).to be_redirect
      end
    end

    context "user has permission to manage admins" do
      before { user.user_permissions.create(permission_slug: :manage_admins) }
      it "responsd with ok" do
        delete :destroy, params: {id: existing_admin.id}

        expect(response).to be_redirect
      end
    end
  end

  describe "#update" do
    let(:organization) { create(:organization) }
    let(:facility_group) { create(:facility_group, organization: organization) }

    let(:full_name) { Faker::Name.name }
    let(:email) { Faker::Internet.email }
    let(:role) { "Test User Role" }

    let(:params) do
      {full_name: full_name,
        email: email,
        role: role,
        organization_id: organization.id}
    end

    let(:permission_params) do
      [{permission_slug: :manage_organizations},
        {permission_slug: :manage_facility_groups,
          resource_type: "Organization",
          resource_id: organization.id},
        {permission_slug: :manage_facilities,
          resource_type: "FacilityGroup",
          resource_id: facility_group.id}]
    end

    let(:existing_admin) { create(:admin, params) }

    context "user does not have permission to manage admins" do
      it "redirects the user" do
        put :update, params: params.merge(id: existing_admin.id)

        expect(response).to be_redirect
      end
    end

    context "user has permission to manage admins" do
      before { user.user_permissions.create(permission_slug: :manage_admins) }

      context "update params are valid" do
        it "allows updating user full name" do
          new_name = Faker::Name.name
          put :update, params: params.merge(id: existing_admin.id, full_name: new_name)

          existing_admin.reload

          expect(response).to be_ok
          expect(existing_admin.full_name).to eq(new_name)
        end

        it "allows updating user role" do
          new_role = "New user role"
          put :update, params: params.merge(id: existing_admin.id, role: new_role)

          existing_admin.reload

          expect(response).to be_ok
          expect(existing_admin.role).to eq(new_role)
        end

        it "does not allow updating user email" do
          new_email = Faker::Internet.email
          put :update, params: params.merge(id: existing_admin.id, email: new_email)

          existing_admin.reload

          expect(response).to be_ok
          expect(existing_admin.role).not_to eq(new_email)
        end

        it "updates user permissions" do
          put :update, params: params.merge(id: existing_admin.id, permissions: permission_params)

          existing_admin.reload
          expect(existing_admin.user_permissions.pluck(:permission_slug))
            .to match_array(permission_params.map { |p| p[:permission_slug].to_s })
        end
      end

      context "update params are invalid" do
        it "responds with bad request if full name is missing" do
          put :update, params: params.merge(id: existing_admin.id, full_name: nil)

          expect(response).to be_bad_request
          expect(JSON(response.body)).to eq("errors" => ["Full name can't be blank"])
        end

        it "responds with bad request if role is missing" do
          put :update, params: params.merge(id: existing_admin.id, role: nil)

          expect(response).to be_bad_request
          expect(JSON(response.body)).to eq("errors" => ["Role can't be blank"])
        end
      end
    end
  end

  describe "#access_tree" do
    let(:organization) { create(:organization) }
    let(:current_admin) {
      current_admin = create(:admin, :manager, organization: organization)
      current_admin.accesses.create!(resource: organization)
      current_admin
    }
    let(:existing_admin) {
      admin = create(:admin, :manager, organization: organization)
      admin.accesses.create!(resource: organization)
      admin
    }

    before do
      facility_group_1 = create(:facility_group, organization: organization)
      facility_group_2 = create(:facility_group, organization: organization)
      create(:facility, facility_group: facility_group_1)
      create(:facility, facility_group: facility_group_2)

      enable_flag(:new_permissions_system_aug_2020, current_admin)
      sign_in(current_admin.email_authentication)
    end

    after do
      disable_flag(:new_permissions_system_aug_2020, current_admin)
    end

    it "pulls up the tree for the admin when the page is show" do
      access_tree = AdminAccessPresenter.new(existing_admin).visible_access_tree

      expected_locals = {
        tree: access_tree[:data],
        root: :facility_group,
        user_being_edited: nil,
        tree_depth: 0,
        page: :show,
      }

      expect(controller).to receive(:render).with({
        partial: access_tree[:render_partial],
        locals: expected_locals,
        status: :no_content
      })

      get :access_tree, params: {id: existing_admin.id, page: :show}, xhr: true
    end

    it "pulls up the tree for the current admin when the page is new" do
      access_tree = AdminAccessPresenter.new(current_admin).visible_access_tree

      expected_locals = {
        tree: access_tree[:data],
        root: :facility_group,
        user_being_edited: nil,
        tree_depth: 0,
        page: :new,
      }

      expect(controller).to receive(:render).with({
        partial: access_tree[:render_partial],
        locals: expected_locals,
        status: :no_content
      })

      get :access_tree, params: {id: current_admin.id, page: :new}, xhr: true
    end

    it "sets the admin as the user_being_edited when the page is edit" do
      access_tree = AdminAccessPresenter.new(current_admin).visible_access_tree

      expected_locals = {
        tree: access_tree[:data],
        root: :facility_group,
        user_being_edited: existing_admin,
        tree_depth: 0,
        page: :edit,
      }

      expect(controller).to receive(:render).with({
        partial: access_tree[:render_partial],
        locals: expected_locals,
        status: :no_content
      })

      get :access_tree, params: {id: existing_admin.id, page: :edit}, xhr: true
    end

    it "returns a 404 if the page is invalid" do
      get :access_tree, params: {id: existing_admin.id, page: :garble}

      expect(response).to be_not_found
    end
  end
end
