# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ErrorTracesController, type: :controller do
  let(:admin) { create(:admin, :power_user) }

  it "denies anon users" do
    post :create
    expect(response).to be_redirect
  end

  it "denies non power user admins" do
    manager = create(:admin, :manager)
    sign_in manager.email_authentication
    post :create
    expect(response).to be_redirect
  end

  it "creates an error" do
    sign_in admin.email_authentication
    expect {
      post :create
    }.to raise_error(Admin::ErrorTracesController::Boom)
  end

  it "submits a sidekiq job to create an error" do
    sign_in admin.email_authentication
    Sidekiq::Testing.inline! do
      expect {
        post :create, params: {type: :job}
      }.to raise_error(Admin::ErrorTracesController::Boom, "Error trace triggered via sidekiq!")
    end
  end
end
