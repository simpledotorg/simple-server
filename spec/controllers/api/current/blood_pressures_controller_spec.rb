require 'rails_helper'

RSpec.describe Api::Current::BloodPressuresController, type: :controller do
  let(:request_user) { FactoryBot.create(:user, :with_phone_number_authentication) }
  let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
  before :each do
    request.env['X_USER_ID'] = request_user.id
    request.env['X_FACILITY_ID'] = request_facility.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  let(:model) { BloodPressure }

  let(:build_payload) { lambda { build_blood_pressure_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_blood_pressure_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { lambda { |blood_pressure| updated_blood_pressure_payload blood_pressure } }
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
    it_behaves_like 'a working sync controller updating records'

    describe 'creates new blood pressures' do
      before :each do
        request.env['HTTP_X_USER_ID'] = request_user.id
        request.env['HTTP_X_FACILITY_ID'] = request_facility.id
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
      end

      it 'creates new blood pressures with associated patient' do
        patient = FactoryBot.create(:patient)
        blood_pressures = (1..3).map do
          build_blood_pressure_payload(FactoryBot.build(:blood_pressure, patient: patient))
        end
        post(:sync_from_user, params: { blood_pressures: blood_pressures }, as: :json)
        expect(BloodPressure.count).to eq 3
        expect(patient.blood_pressures.count).to eq 3
        expect(response).to have_http_status(200)
      end

      context 'recorded_at is sent' do
        it 'sets the recorded_at sent in the params' do
          recorded_at = 1.month.ago
          blood_pressure = build_blood_pressure_payload(FactoryBot.build(:blood_pressure, recorded_at: recorded_at))

          post(:sync_from_user, params: { blood_pressures: [blood_pressure] }, as: :json)

          bp = BloodPressure.find(blood_pressure['id'])
          expect(bp.recorded_at.to_i).to eq(recorded_at.to_i)
        end

        it 'does not modify the recorded_at for a patient if params have recorded_at' do
          patient_recorded_at = 4.months.ago
          patient = FactoryBot.create(:patient, recorded_at: patient_recorded_at)
          older_bp_recording_date = 5.months.ago
          blood_pressure = build_blood_pressure_payload(FactoryBot.build(:blood_pressure,
                                                                         patient: patient,
                                                                         recorded_at: older_bp_recording_date))
          post(:sync_from_user, params: { blood_pressures: [blood_pressure] }, as: :json)

          patient.reload
          expect(patient.recorded_at.to_i).to eq(patient_recorded_at.to_i)
        end
      end

      context 'recorded_at is not sent' do
        it 'defaults recorded_at to device_created_at' do
          blood_pressure = build_blood_pressure_payload(FactoryBot.build(:blood_pressure)).except('recorded_at')
          post(:sync_from_user, params: { blood_pressures: [blood_pressure] }, as: :json)

          bp = BloodPressure.find(blood_pressure['id'])
          expect(bp.recorded_at).to eq(bp.device_created_at)
        end

        it "sets patient's recorded_at to bp's device_created_at if the bp is older" do
          patient = FactoryBot.create(:patient)
          older_bp_recording_date = 2.months.ago
          blood_pressure = build_blood_pressure_payload(
            FactoryBot.build(:blood_pressure,
                             patient: patient,
                             device_created_at: older_bp_recording_date)).except('recorded_at')
          post(:sync_from_user, params: { blood_pressures: [blood_pressure] }, as: :json)

          patient.reload
          expect(patient.recorded_at.to_i).to eq(older_bp_recording_date.to_i)
        end

        it "sets patient's recorded_at to their oldest bp's device_created_at" do
          patient = FactoryBot.create(:patient)
          two_months_ago = 2.months.ago
          three_months_ago = 3.months.ago
          bp_recorded_two_months_ago = build_blood_pressure_payload(
            FactoryBot.build(:blood_pressure,
                             patient: patient,
                             device_created_at: two_months_ago))
                                         .except('recorded_at')
          bp_recorded_three_months_ago = build_blood_pressure_payload(
            FactoryBot.build(:blood_pressure,
                             patient: patient,
                             device_created_at: three_months_ago))
                                           .except('recorded_at')

          post(:sync_from_user, params: { blood_pressures: [bp_recorded_three_months_ago] }, as: :json)
          post(:sync_from_user, params: { blood_pressures: [bp_recorded_two_months_ago] }, as: :json)

          patient.reload
          expect(patient.recorded_at.to_i).to eq(three_months_ago.to_i)
        end
      end
    end
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working Current sync controller sending records'

    describe 'current facility prioritisation' do
      it "syncs request facility's records first" do
        request_2_facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
        FactoryBot.create_list(:blood_pressure, 2, facility: request_facility, updated_at: 3.minutes.ago)
        FactoryBot.create_list(:blood_pressure, 2, facility: request_facility, updated_at: 5.minutes.ago)
        FactoryBot.create_list(:blood_pressure, 2, facility: request_2_facility, updated_at: 7.minutes.ago)
        FactoryBot.create_list(:blood_pressure, 2, facility: request_2_facility, updated_at: 10.minutes.ago)

        # GET request 1
        set_authentication_headers
        get :sync_to_user, params: { limit: 4 }
        response_1_body = JSON(response.body)

        record_ids = response_1_body['blood_pressures'].map { |r| r['id'] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:facility).to_set).to eq Set[request_facility]

        # GET request 2
        get :sync_to_user, params: { limit: 4, process_token: response_1_body['process_token'] }
        response_2_body = JSON(response.body)

        record_ids = response_2_body['blood_pressures'].map { |r| r['id'] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:facility).to_set).to eq Set[request_facility, request_2_facility]
      end
    end

    describe 'syncing within a facility group' do
      let(:facility_in_same_group) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
      let(:facility_in_another_group) { FactoryBot.create(:facility) }

      before :each do
        set_authentication_headers
        FactoryBot.create_list(:blood_pressure, 2, facility: facility_in_another_group, updated_at: 3.minutes.ago)
        FactoryBot.create_list(:blood_pressure, 2, facility: facility_in_same_group, updated_at: 5.minutes.ago)
        FactoryBot.create_list(:blood_pressure, 2, facility: request_facility, updated_at: 7.minutes.ago)
      end

      it "only sends data for facilities belonging in the sync group of user's registration facility" do
        get :sync_to_user, params: { limit: 6 }

        response_blood_pressures = JSON(response.body)['blood_pressures']
        response_facilities = response_blood_pressures.map { |blood_pressure| blood_pressure['facility_id'] }.to_set

        expect(response_blood_pressures.count).to eq 4
        expect(response_facilities).to match_array([request_facility.id, facility_in_same_group.id])
        expect(response_facilities).not_to include(facility_in_another_group.id)
      end
    end
  end
end
