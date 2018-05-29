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
  describe 'GET sync: send data from server to device;' do
    before :each do
      Timecop.travel(15.minutes.ago) do
        FactoryBot.create_list(:blood_pressure, 10)
      end
    end

    it 'Returns records from the beginning of time, when processed_since is not set' do
      get :sync_to_user

      response_body = JSON(response.body)
      expect(response_body['blood_pressures'].count).to eq BloodPressure.count
      expect(response_body['blood_pressures'].map { |blood_pressure| blood_pressure['id'] }.to_set)
        .to eq(BloodPressure.all.pluck(:id).to_set)
    end

    it 'Returns new blood pressures added since last sync' do
      expected_blood_pressures = FactoryBot.create_list(:blood_pressure, 5, updated_at: 5.minutes.ago)
      get :sync_to_user, params: { processed_since: 10.minutes.ago }

      response_body = JSON(response.body)
      expect(response_body['blood_pressures'].count).to eq 5

      expect(response_body['blood_pressures'].map { |blood_pressure| blood_pressure['id'] }.to_set)
        .to eq(expected_blood_pressures.map(&:id).to_set)

      expect(response_body['processed_since'].to_time.to_i)
        .to eq(expected_blood_pressures.map(&:updated_at).max.to_i)
    end

    describe 'nothing to sync' do
      it 'Returns an empty list when there is nothing to sync' do
        sync_time = 10.minutes.ago
        get :sync_to_user, params: { processed_since: sync_time }
        response_body = JSON(response.body)
        expect(response_body['blood_pressures'].count).to eq 0
        expect(response_body['processed_since'].to_time.to_i).to eq sync_time.to_i
      end

    end

    describe 'batching' do
      it 'Returns the number of records requested with limit' do
        get :sync_to_user, params: { processed_since: 20.minutes.ago,
                                     limit:           2 }
        response_body = JSON(response.body)
        expect(response_body['blood_pressures'].count).to eq 2
      end

      it 'Returns all the records on server over multiple small batches' do
        get :sync_to_user, params: { processed_since: 20.minutes.ago,
                                     limit:           7 }
        response_1 = JSON(response.body)

        get :sync_to_user, params: { processed_since: response_1['processed_since'],
                                     limit:           7 }

        response_2 = JSON(response.body)

        received_blood_pressures = response_1['blood_pressures'].concat(response_2['blood_pressures']).to_set
        expect(received_blood_pressures.count).to eq BloodPressure.count

        expect(received_blood_pressures.to_set)
          .to eq JSON(BloodPressure.all.map(&:nested_hash).to_json).to_set
      end
    end
  end
end
