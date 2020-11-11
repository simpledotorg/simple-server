require "rails_helper"

RSpec.describe Api::V3::MedicalHistoriesController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { MedicalHistory }
  let(:build_payload) { -> { build_medical_history_payload } }
  let(:build_invalid_payload) { -> { build_invalid_medical_history_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { ->(medical_history) { updated_medical_history_payload medical_history } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  before :each do
    request.env["X_USER_ID"] = request_user.id
    request.env["X_FACILITY_ID"] = request_facility.id
    request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
  end

  def create_record(options = {})
    facility = create(:facility, facility_group: request_facility_group)
    patient = build(:patient, registration_facility: facility)
    create(:medical_history, options.merge(patient: patient))
  end

  def create_record_list(n, options = {})
    facility = create(:facility, facility_group_id: request_facility_group.id)
    patient = build(:patient, registration_facility_id: facility.id)
    create_list(:medical_history, n, options.merge(patient: patient))
  end

  it_behaves_like "a sync controller that authenticates user requests"
  it_behaves_like "a sync controller that audits the data access"

  describe "POST sync: send data from device to server;" do
    it_behaves_like "a working sync controller creating records"
    it_behaves_like "a working sync controller updating records"
  end

  describe "GET sync: send data from server to device;" do
    it_behaves_like "a working V3 sync controller sending records"

    context "patient prioritisation" do
      let(:facility_in_same_group) { create(:facility, facility_group: request_facility_group) }
      let(:patient_in_request_facility) { build(:patient, registration_facility: request_facility) }
      let(:patient_in_same_group) { build(:patient, registration_facility: facility_in_same_group) }

      it "syncs records for patients in the request facility first" do
        create_list(:medical_history, 2, patient: patient_in_request_facility, updated_at: 3.minutes.ago)
        create_list(:medical_history, 2, patient: patient_in_request_facility, updated_at: 5.minutes.ago)
        create_list(:medical_history, 2, patient: patient_in_same_group, updated_at: 7.minutes.ago)
        create_list(:medical_history, 2, patient: patient_in_same_group, updated_at: 10.minutes.ago)

        # GET request 1
        set_authentication_headers
        get :sync_to_user, params: {limit: 4}
        response_1_body = JSON(response.body)

        response_1_record_ids = response_1_body["medical_histories"].map { |r| r["id"] }
        response_1_records = model.where(id: response_1_record_ids)
        expect(response_1_records.count).to eq 4
        expect(response_1_records.map(&:patient).to_set).to eq Set[patient_in_request_facility]

        # GET request 2
        get :sync_to_user, params: {limit: 4, process_token: response_1_body["process_token"]}
        response_2_body = JSON(response.body)

        response_2_record_ids = response_2_body["medical_histories"].map { |r| r["id"] }
        response_2_records = model.where(id: response_2_record_ids)
        expect(response_2_records.count).to eq 4
        expect(response_2_records.map(&:patient).to_set).to eq Set[patient_in_request_facility, patient_in_same_group]
      end
    end

    context "region-level sync" do
      let!(:facility_in_same_block) {
        create(:facility,
          state: request_facility.state,
          block: request_facility.block,
          facility_group: request_facility_group)
      }

      let!(:facility_in_another_block) {
        create(:facility, block: "Another Block", facility_group: request_facility_group)
      }

      let!(:facility_in_another_group) {
        create(:facility, facility_group: create(:facility_group))
      }

      let(:patient_in_request_facility) { create(:patient, :without_medical_history, registration_facility: request_facility) }
      let(:patient_in_same_block) { create(:patient, :without_medical_history, registration_facility: facility_in_same_block) }
      let(:patient_assigned_to_block) { create(:patient, :without_medical_history, assigned_facility: facility_in_same_block) }
      let(:patient_with_appointment_in_block) {
        create(:patient, :without_medical_history)
          .yield_self { |patient| create(:appointment, patient: patient, facility: facility_in_same_block) }
          .yield_self { |appointment| appointment.patient }
      }
      let(:patient_in_another_block) { create(:patient, :without_medical_history, registration_facility: facility_in_another_block) }
      let(:patient_in_another_facility_group) { create(:patient, :without_medical_history, registration_facility: facility_in_another_group) }
      let(:process_token) { Base64.encode64({sync_region_id: request_facility.region.block}.to_json) }

      before :each do
        # TODO: replace with proper factory data
        RegionBackfill.call(dry_run: false)
        set_authentication_headers
      end

      after :each do
        disable_flag(:region_level_sync, request_user)
      end

      context "region-level sync is turned on" do
        before :each do
          enable_flag(:region_level_sync, request_user)
        end

        it "only sends data belonging to the patients in the block of user's facility" do
          expected_records = [
            *create_list(:medical_history, 2, patient: patient_in_request_facility),
            *create_list(:medical_history, 2, patient: patient_in_same_block),
            *create_list(:medical_history, 2, patient: patient_assigned_to_block),
            *create_list(:medical_history, 2, patient: patient_with_appointment_in_block)
          ]

          not_expected_records = [
            *create_list(:medical_history, 2, patient: patient_in_another_block),
            *create_list(:medical_history, 2, patient: patient_in_another_facility_group)
          ]

          get :sync_to_user, params: {process_token: process_token}

          response_records = JSON(response.body)["medical_histories"]
          response_records.each { |r| expect(r["id"]).to be_in(expected_records.map(&:id)) }
          response_records.each { |r| expect(r["id"]).to_not be_in(not_expected_records.map(&:id)) }
        end
      end

      context "region-level sync is turned off" do
        it "defaults to sending data for patients in the user's facility group" do
          expected_records = [
            *create_list(:medical_history, 2, patient: patient_in_request_facility),
            *create_list(:medical_history, 2, patient: patient_in_same_block),
            *create_list(:medical_history, 2, patient: patient_in_another_block)
          ]

          not_expected_records =
            create_list(:medical_history, 2, patient: patient_in_another_facility_group)

          get :sync_to_user, params: {process_token: process_token}

          response_records = JSON(response.body)["medical_histories"]
          response_records.each { |r| expect(r["id"]).to be_in(expected_records.map(&:id)) }
          response_records.each { |r| expect(r["id"]).to_not be_in(not_expected_records.map(&:id)) }
        end
      end
    end
  end
end
