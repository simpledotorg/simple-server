require 'rails_helper'

RSpec.describe Api::V1::BloodPressuresController, type: :controller do
  describe 'POST sync: send data from device to server;' do

    describe 'creates new blood pressures' do

      it 'returns 400 when there are no blood pressures in the request' do
        post(:sync_from_user, params: { blood_pressures: [] })
        expect(response.status).to eq 400
      end

      it 'creates new blood pressures without associated patient' do
        blood_pressures = (1..10).map { build_blood_pressure_payload }
        post(:sync_from_user, params: { blood_pressures: blood_pressures }, as: :json)
        expect(BloodPressure.count).to eq 10
        expect(response).to have_http_status(200)
      end

      it 'creates new blood pressures with associated patient' do
        patient = FactoryBot.create(:patient)
        blood_pressures = (1..10).map do
          build_blood_pressure_payload(FactoryBot.build(:blood_pressure, patient: patient))
        end
        post(:sync_from_user, params: { blood_pressures: blood_pressures }, as: :json)
        expect(BloodPressure.count).to eq 10
        expect(patient.blood_pressures.count).to eq 10
        expect(response).to have_http_status(200)
      end

      it 'returns errors for invalid records' do
        payload = build_invalid_blood_pressure_payload
        post(:sync_from_user, params: { blood_pressures: [payload] }, as: :json)

        blood_pressure_errors = JSON(response.body)['errors'].first
        expect(blood_pressure_errors).to be_present
        expect(blood_pressure_errors['schema']).to be_present
        expect(blood_pressure_errors['id']).to be_present
        expect(blood_pressure_errors['schema'].count).to eq 3
      end

      it 'returns errors for some invalid records, and accepts others' do
        invalid_blood_pressures_payload = (1..5).map { build_invalid_blood_pressure_payload }
        valid_blood_pressures_payload   = (1..5).map { build_blood_pressure_payload }
        post(:sync_from_user, params: { blood_pressures: invalid_blood_pressures_payload + valid_blood_pressures_payload }, as: :json)

        blood_pressure_errors = JSON(response.body)['errors']
        expect(blood_pressure_errors.count).to eq 5
        expect(blood_pressure_errors.map { |error| error['id'] })
          .to match_array(invalid_blood_pressures_payload.map { |blood_pressure| blood_pressure['id'] })

        expect(BloodPressure.count).to eq 5
        expect(BloodPressure.pluck(:id))
          .to match_array(valid_blood_pressures_payload.map { |blood_pressure| blood_pressure['id'] })
      end
    end

    describe 'updates blodo pressures' do

      let(:existing_blood_pressures) { FactoryBot.create_list(:blood_pressure, 10) }
      let(:updated_blood_pressures_payload) { existing_blood_pressures.map { |blood_pressure| updated_blood_pressure_payload blood_pressure } }


      it 'with updated blood_pressure attributes' do
        post :sync_from_user, params: { blood_pressures: updated_blood_pressures_payload }, as: :json

        updated_blood_pressures_payload.each do |updated_blood_pressure|
          db_blood_pressure = BloodPressure.find(updated_blood_pressure['id'])
          expect(with_payload_keys(db_blood_pressure.attributes).with_int_timestamps)
            .to eq(updated_blood_pressure.with_int_timestamps)
        end
      end

    end
  end
end
