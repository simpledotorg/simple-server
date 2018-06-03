require 'rails_helper'

RSpec.describe "Facilities", type: :request do
  describe "GET /facilities" do
    it "works! (now write some real specs)" do
      get facilities_path
      expect(response).to have_http_status(200)
    end
  end
end
