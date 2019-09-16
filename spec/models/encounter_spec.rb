require 'rails_helper'

describe Encounter, type: :model do
  let!(:user) { create(:user) }
  let!(:facility) { create(:facility) }
  let!(:patient) { create(:patient, registration_facility: facility) }
  let!(:blood_pressures) { create_list(:blood_pressure, 2, patient: patient, facility: facility, user: user) }

  context '.create_encounter_with_event!' do
    it 'creates an encounter and associates multiple encounter events with it' do
      params = {
        patient: patient,
        facility: facility,
        encountered_on: Date.today,
        timezone_offset: 3600,
        timezone: 'Asia/Kolkata',
        user: user,
        device_created_at: Time.now,
        device_updated_at: Time.now,
        recorded_at: Time.now,
        encounterables: blood_pressures
      }

      expect {
        Encounter.create_encounter_with_events!(params)
      }.to change { Encounter.count }.by(1).and change { EncounterEvent.count }.by(2)
    end
  end

  context '.encountered_on' do
    it 'returns the encountered_on in the correct timezone' do
      creation_date = Timecop.travel(DateTime.new(2019, 1, 1)) { create(:encounter).device_created_at }

      expect(Encounter.encountered_on(creation_date, 1.day.seconds)).to eq(Date.new(2019, 1, 2))
    end
  end
end
