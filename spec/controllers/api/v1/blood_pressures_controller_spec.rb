require 'rails_helper'

RSpec.describe Api::V1::BloodPressuresController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }

  before :each do
    request.env['HTTP_X_USER_ID'] = request_user.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  let(:model) { BloodPressure }

  let(:build_payload) { lambda { build_blood_pressure_payload_v1 } }
  let(:build_invalid_payload) { lambda { build_invalid_blood_pressure_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { lambda { |blood_pressure| updated_blood_pressure_payload_v1 blood_pressure } }
  let(:number_of_schema_errors_in_invalid_payload) { 3 }

  def create_record(options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    FactoryBot.create(:blood_pressure, options.merge(facility: facility))
  end

  def create_record_list(n, options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    FactoryBot.create_list(:blood_pressure, n, options.merge(facility: facility))
  end

  it_behaves_like 'a sync controller that authenticates user requests'
  it_behaves_like 'a sync controller that audits the data access'
  it_behaves_like 'a working sync controller that short circuits disabled apis'

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'

    describe 'updates records' do
      it 'with updated record attributes' do
        updated_records = create_record_list(1).map(&update_payload)
        updated_payload = Hash['blood_pressures', updated_records]
        post :sync_from_user, params: updated_payload, as: :json

        updated_records.each do |record|
          db_record = BloodPressure.find(record['id'])
          expect(build_blood_pressure_payload_v1(db_record).with_int_timestamps)
            .to eq(record.to_json_and_back.with_int_timestamps)
        end
      end
    end

    describe 'creates new blood pressures' do
      it 'creates new blood pressures with associated patient' do
        patient = FactoryBot.create(:patient)
        blood_pressures = (1..10).map do
          build_blood_pressure_payload_v1(FactoryBot.build(:blood_pressure, patient: patient))
        end
        post(:sync_from_user, params: { blood_pressures: blood_pressures }, as: :json)
        expect(BloodPressure.count).to eq 10
        expect(patient.blood_pressures.count).to eq 10
        expect(response).to have_http_status(200)
      end

      it 'defaults recorded_at to device_created_at' do
        patient = FactoryBot.create(:patient)
        blood_pressure = build_blood_pressure_payload_v1(FactoryBot.build(:blood_pressure, patient: patient))
        post(:sync_from_user, params: { blood_pressures: [blood_pressure] }, as: :json)

        patient.reload
        blood_pressure_in_db = patient.blood_pressures.first
        expect(blood_pressure_in_db.recorded_at).to eq(blood_pressure_in_db.device_created_at)
      end

      it "sets patient's recorded_at to bp's device_created_at if it is older than itself" do
        patient = FactoryBot.create(:patient)
        older_blood_pressure_recording_date = patient.device_created_at - 1.month
        blood_pressure = build_blood_pressure_payload_v1(
          FactoryBot.build(:blood_pressure,
                           patient: patient,
                           device_created_at: older_blood_pressure_recording_date))
        post(:sync_from_user, params: { blood_pressures: [blood_pressure] }, as: :json)

        patient.reload
        blood_pressure_in_db = patient.blood_pressures.first
        expect(patient.recorded_at).to eq(blood_pressure_in_db.device_created_at)
      end

      it "sets patient's recorded_at to their oldest bp's device_created_at" do
        patient = FactoryBot.create(:patient)
        one_month_ago = patient.device_created_at - 1.months
        two_months_ago = patient.device_created_at - 2.months
        blood_pressure_recorded_one_month_ago = build_blood_pressure_payload_v1(
          FactoryBot.build(:blood_pressure,
                           patient: patient,
                           device_created_at: one_month_ago))
        blood_pressure_recorded_two_months_ago = build_blood_pressure_payload_v1(
          FactoryBot.build(:blood_pressure,
                           patient: patient,
                           device_created_at: two_months_ago))
        post(:sync_from_user, params: { blood_pressures: [blood_pressure_recorded_two_months_ago] }, as: :json)
        post(:sync_from_user, params: { blood_pressures: [blood_pressure_recorded_one_month_ago] }, as: :json)

        patient.reload
        expect(patient.recorded_at.to_i).to eq(two_months_ago.to_i)
      end
    end
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working V1 sync controller sending records'
  end

  describe 'syncing within a facility group' do
    let(:facility_in_same_group) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
    let(:facility_in_another_group) { FactoryBot.create(:facility) }

    before :each do
      set_authentication_headers
      FactoryBot.create_list(:blood_pressure, 5, facility: facility_in_another_group, updated_at: 3.minutes.ago)
      FactoryBot.create_list(:blood_pressure, 5, facility: facility_in_same_group, updated_at: 5.minutes.ago)
    end

    it "only sends data for facilities belonging in the sync group of user's registration facility" do
      get :sync_to_user, params: { limit: 15 }

      response_blood_pressures = JSON(response.body)['blood_pressures']
      response_facilities = response_blood_pressures.map { |blood_pressure| blood_pressure['facility_id']}.to_set

      expect(response_blood_pressures.count).to eq 5
      expect(response_facilities).not_to include(facility_in_another_group.id)
    end
  end
end
