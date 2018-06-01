require 'rails_helper'

RSpec.describe Api::V1::BloodPressuresController, type: :controller do
  let(:model) { BloodPressure }

  let(:empty_payload) { { blood_pressures: [] } }

  let(:new_records) { (1..10).map { build_blood_pressure_payload } }
  let(:new_records_payload) { { blood_pressures: new_records } }

  let(:existing_records) { FactoryBot.create_list(:blood_pressure, 10) }
  let(:updated_records) { existing_records.map { |blood_pressure| updated_blood_pressure_payload blood_pressure } }
  let(:updated_payload) { { blood_pressures: updated_records } }

  let(:invalid_record) { build_invalid_blood_pressure_payload }
  let(:invalid_payload) { { blood_pressures: [invalid_record] } }
  let(:number_of_schema_errors) { 3 }

  let(:invalid_records_payload) { (1..5).map { build_invalid_blood_pressure_payload } }
  let(:valid_records_payload) { (1..5).map { build_blood_pressure_payload } }
  let(:partially_valid_payload) { { blood_pressures: invalid_records_payload + valid_records_payload }}

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'sync controller - create new records'
    it_behaves_like 'sync controller - update exiting records'

    describe 'creates new blood pressures' do
      it 'creates new blood pressures with associated patient' do
        patient         = FactoryBot.create(:patient)
        blood_pressures = (1..10).map do
          build_blood_pressure_payload(FactoryBot.build(:blood_pressure, patient: patient))
        end
        post(:sync_from_user, params: { blood_pressures: blood_pressures }, as: :json)
        expect(BloodPressure.count).to eq 10
        expect(patient.blood_pressures.count).to eq 10
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'sync controller - get records'
  end
end
