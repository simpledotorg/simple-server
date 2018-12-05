require 'rails_helper'

RSpec.describe Api::Current::PrescriptionDrugsController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }
  let(:request_facility) { FactoryBot.create(:facility) }
  let(:model) { PrescriptionDrug }

  let(:build_payload) { lambda { build_prescription_drug_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_prescription_drug_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { lambda { |prescription_drug| updated_prescription_drug_payload prescription_drug } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  def create_record(options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    FactoryBot.create(:prescription_drug, options.merge(facility: facility))
  end

  def create_record_list(n, options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    FactoryBot.create_list(:prescription_drug, n, options.merge(facility: facility))
  end

  it_behaves_like 'a sync controller that authenticates user requests'
  it_behaves_like 'a sync controller that audits the data access'
  it_behaves_like 'a working sync controller that short circuits disabled apis'

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'
    it_behaves_like 'a working sync controller updating records'

    describe 'creates new prescription drugs' do
      it 'creates new prescription drugs with associated patient, and facility' do
        request.env['HTTP_X_USER_ID'] = request_user.id
        request.env['HTTP_X_FACILITY_ID'] = request_facility.id
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"

        patient = FactoryBot.create(:patient)
        facility = FactoryBot.create(:facility)
        prescription_drugs = (1..10).map do
          build_prescription_drug_payload(FactoryBot.build(:prescription_drug,
                                                           patient: patient,
                                                           facility: facility))
        end
        post(:sync_from_user, params: { prescription_drugs: prescription_drugs }, as: :json)
        expect(PrescriptionDrug.count).to eq 10
        expect(patient.prescription_drugs.count).to eq 10
        expect(facility.prescription_drugs.count).to eq 10
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working Current sync controller sending records'

    describe 'current facility prioritisation' do
      it "syncs request facility's records first" do
        request_2_facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
        FactoryBot.create_list(:prescription_drug, 5, facility: request_facility, updated_at: 3.minutes.ago)
        FactoryBot.create_list(:prescription_drug, 5, facility: request_facility, updated_at: 5.minutes.ago)
        FactoryBot.create_list(:prescription_drug, 5, facility: request_2_facility, updated_at: 7.minutes.ago)
        FactoryBot.create_list(:prescription_drug, 5, facility: request_2_facility, updated_at: 10.minutes.ago)

        # GET request 1
        set_authentication_headers
        get :sync_to_user, params: { limit: 10 }
        response_1_body = JSON(response.body)

        record_ids = response_1_body['prescription_drugs'].map { |r| r['id'] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 10
        expect(records.map(&:facility).to_set).to eq Set[request_facility]

        # GET request 2
        get :sync_to_user, params: { limit: 10, process_token: response_1_body['process_token'] }
        response_2_body = JSON(response.body)

        record_ids = response_2_body['prescription_drugs'].map { |r| r['id'] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 10
        expect(records.map(&:facility).to_set).to eq Set[request_facility, request_2_facility]
      end
    end

    describe 'syncing within a sync group' do
      let(:facility_in_same_group) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
      let(:facility_in_another_group) { FactoryBot.create(:facility) }

      before :each do
        set_authentication_headers
        FactoryBot.create_list(:prescription_drug, 5, facility: facility_in_another_group, updated_at: 3.minutes.ago)
        FactoryBot.create_list(:prescription_drug, 5, facility: facility_in_same_group, updated_at: 5.minutes.ago)
        FactoryBot.create_list(:prescription_drug, 5, facility: request_facility, updated_at: 7.minutes.ago)
      end

      it "only sends data for facilities belonging in the sync group of user's registration facility" do
        get :sync_to_user, params: { limit: 15 }

        response_prescription_drugs = JSON(response.body)['prescription_drugs']
        response_facilities = response_prescription_drugs.map { |prescription_drug| prescription_drug['facility_id']}.to_set

        # expect(response_appointments.count).to eq 10
        # expect(response_facilities).to match_array([request_facility.id, facility_in_same_group.id])
        expect(response_facilities).not_to include(facility_in_another_group.id)
      end
    end
  end
end
