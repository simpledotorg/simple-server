require 'rails_helper'

RSpec.describe Api::Current::BloodSugarsController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
  before :each do
    request.env['X_USER_ID'] = request_user.id
    request.env['X_FACILITY_ID'] = request_facility.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  let(:model) { BloodSugar }

  let(:build_payload) { lambda { build_blood_sugar_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_blood_sugar_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { lambda { |blood_sugar| updated_blood_sugar_payload(blood_sugar) } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  def create_record(options = {})
    facility = create(:facility, facility_group: request_user.facility.facility_group)
    record = create(:blood_sugar, { facility: facility }.merge(options))
    create(:encounter, :with_observables, observable: record)
    record
  end

  def create_record_list(n, options = {})
    facility = create(:facility, facility_group: request_user.facility.facility_group)
    records = create_list(:blood_sugar, n, { facility: facility }.merge(options))
    records.each { |r| create(:encounter, :with_observables, observable: r) }
    records
  end

  it_behaves_like 'a sync controller that authenticates user requests'
  it_behaves_like 'a sync controller that audits the data access'
  it_behaves_like 'a working sync controller that short circuits disabled apis'

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'

    describe 'a working sync controller updating records' do
      let(:request_key) { model.to_s.underscore.pluralize }
      let(:existing_records) { create_record_list(10) }
      let(:updated_records) { existing_records.map(&update_payload) }
      let(:updated_payload) { Hash[request_key, updated_records] }

      before :each do
        set_authentication_headers
      end

      describe 'updates records' do
        it 'with updated record attributes' do
          post :sync_from_user, params: updated_payload, as: :json

          updated_records.each do |record|
            db_record = model.find(record['id'])
            expect(db_record.attributes.to_json_and_back.with_payload_keys.with_int_timestamps)
              .to eq(record.to_json_and_back.with_int_timestamps)
          end
        end
      end
    end

    describe 'creates new blood sugars' do
      before :each do
        request.env['HTTP_X_USER_ID'] = request_user.id
        request.env['HTTP_X_FACILITY_ID'] = request_facility.id
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
      end

      it 'creates new blood sugars with associated patient' do
        patient = create(:patient)
        blood_sugars = (1..3).map do
          build_blood_sugar_payload(build(:blood_sugar, patient: patient))
        end
        post(:sync_from_user, params: { blood_sugars: blood_sugars }, as: :json)
        expect(BloodSugar.count).to eq 3
        expect(patient.blood_sugars.count).to eq 3
        expect(response).to have_http_status(200)
      end

      context 'recorded_at is sent' do
        it 'sets the recorded_at sent in the params' do
          recorded_at = 1.month.ago
          blood_sugar = build_blood_sugar_payload(build(:blood_sugar, recorded_at: recorded_at))

          post(:sync_from_user, params: { blood_sugars: [blood_sugar] }, as: :json)

          bp = BloodSugar.find(blood_sugar['id'])
          expect(bp.recorded_at.to_i).to eq(recorded_at.to_i)
        end

        it 'does not modify the recorded_at for a patient if params have recorded_at' do
          patient_recorded_at = 4.months.ago
          patient = create(:patient, recorded_at: patient_recorded_at)
          older_bp_recording_date = 5.months.ago
          blood_sugar = build_blood_sugar_payload(build(:blood_sugar,
                                                        patient: patient,
                                                        recorded_at: older_bp_recording_date))
          post(:sync_from_user, params: { blood_sugars: [blood_sugar] }, as: :json)

          patient.reload
          expect(patient.recorded_at.to_i).to eq(patient_recorded_at.to_i)
        end
      end
    end
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working Current sync controller sending records'

    describe 'current facility prioritisation' do
      it "syncs request facility's records first" do
        request_2_facility = create(:facility, facility_group: request_user.facility.facility_group)

        create_record_list(2, facility: request_facility, updated_at: 3.minutes.ago)
        create_record_list(2, facility: request_facility, updated_at: 5.minutes.ago)
        create_record_list(2, facility: request_2_facility, updated_at: 7.minutes.ago)
        create_record_list(2, facility: request_2_facility, updated_at: 10.minutes.ago)

        # GET request 1
        set_authentication_headers
        get :sync_to_user, params: { limit: 4 }
        response_1_body = JSON(response.body)

        record_ids = response_1_body['blood_sugars'].map { |r| r['id'] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:facility).to_set).to eq Set[request_facility]

        # GET request 2
        get :sync_to_user, params: { limit: 4, process_token: response_1_body['process_token'] }
        response_2_body = JSON(response.body)

        record_ids = response_2_body['blood_sugars'].map { |r| r['id'] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:facility).to_set).to eq Set[request_facility, request_2_facility]
      end
    end

    describe 'syncing within a facility group' do
      let(:facility_in_same_group) { create(:facility, facility_group: request_user.facility.facility_group) }
      let(:facility_in_another_group) { create(:facility) }

      before :each do
        set_authentication_headers

        create_record_list(2, facility: facility_in_another_group, updated_at: 3.minutes.ago)
        create_record_list(2, facility: facility_in_same_group, updated_at: 5.minutes.ago)
        create_record_list(2, facility: request_facility, updated_at: 7.minutes.ago)
      end

      it "only sends data for facilities belonging in the sync group of user's registration facility" do
        get :sync_to_user, params: { limit: 6 }

        response_blood_sugars = JSON(response.body)['blood_sugars']
        response_facilities = response_blood_sugars.map { |blood_sugar| blood_sugar['facility_id'] }.to_set

        expect(response_blood_sugars.count).to eq 4
        expect(response_facilities).to match_array([request_facility.id, facility_in_same_group.id])
        expect(response_facilities).not_to include(facility_in_another_group.id)
      end
    end
  end
end
