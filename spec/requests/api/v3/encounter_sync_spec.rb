require "rails_helper"

RSpec.describe "Encounters sync", type: :request do
  let(:sync_route) { "/api/v3/encounters/sync" }
  let(:facility) { create(:facility) }
  let(:request_user) { create(:user, registration_facility: facility) }
  let(:patient) { create(:patient, registration_user: request_user, registration_facility: facility) }

  let(:model) { Encounter }

  let(:build_payload) do
    lambda {
      build_encounters_payload(build(:encounter, facility: patient.registration_facility, patient: patient))
    }
  end

  let(:build_invalid_payload) { -> { build_invalid_encounters_payload } }
  let(:update_payload) { ->(encounter) { updated_encounters_payload(encounter) } }

  def to_response(encounter)
    Api::V3::EncounterTransformer.to_response(encounter)
  end

  around do |example|
    Flipper.enable(:sync_encounters)
    example.run
    Flipper.disable(:sync_encounters)
  end

  include_examples "v3 API sync requests"
end
