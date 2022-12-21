require "rails_helper"

RSpec.describe "Questionnaires sync", type: :request do
  let(:sync_route) { "/api/v4/questionnaire/sync" }
  let(:request_user) { create(:user) }

  include_examples "v4 API sync requests"
end
