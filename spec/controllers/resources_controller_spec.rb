# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResourcesController, type: :controller do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin.email_authentication)
  end

  describe "GET #index" do
    render_views

    it "returns a success response" do
      get :index, params: {}

      expect(response).to be_successful
    end
  end
end
