require 'rails_helper'

describe Encounter, type: :model do
  let!(:user) { create(:user) }
  let!(:facility) { create(:facility) }
  let!(:patient) { create(:patient, registration_facility: facility) }

  context '#encountered_on' do
    it 'returns the encountered_on in the correct timezone' do
      Timecop.travel(DateTime.new(2019, 1, 1)) {
        expect(create(:encounter, timezone_offset: 24 * 60 * 60).encountered_on).to eq(Date.new(2019, 1, 2))
      }
    end
  end
end
