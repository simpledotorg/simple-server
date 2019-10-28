require 'rails_helper'

RSpec.describe 'Encounters sync', type: :request do
  let(:sync_route) { '/api/v3/encounters/sync' }
  let(:facility) { create(:facility) }
  let(:request_user) { create(:user, registration_facility: facility) }
  let(:patient) { create(:patient, registration_user: request_user, registration_facility: facility) }

  let(:model) { Encounter }

  let(:build_payload) {
    lambda {
      build_encounters_payload(build(:encounter, facility: patient.registration_facility, patient: patient))
    }
  }

  let(:build_invalid_payload) { lambda { build_invalid_encounters_payload } }
  let(:update_payload) { lambda { |encounter| updated_encounters_payload(encounter) } }

  def to_response(encounter)
    Api::Current::EncounterTransformer.to_response(encounter)
  end

  include_examples 'current API sync requests'
end
