require "rails_helper"

RSpec.describe Api::V3::AppointmentsController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { Appointment }
  let(:build_payload) { -> { build_appointment_payload } }
  let(:build_invalid_payload) { -> { build_invalid_appointment_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { ->(appointment) { updated_appointment_payload appointment } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  before :each do
    request.env["X_USER_ID"] = request_user.id
    request.env["X_FACILITY_ID"] = request_facility.id
    request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
  end

  def create_record(options = {})
    facility = options[:facility] || create(:facility, facility_group: request_facility_group)
    patient = create(:patient, registration_facility: facility)
    create(:appointment, {patient: patient}.merge(options))
  end

  def create_record_list(n, options = {})
    facility = options[:facility] || create(:facility, facility_group: request_facility_group)
    patient = create(:patient, registration_facility: facility)
    create_list(:appointment, n, {patient: patient}.merge(options))
  end

  it_behaves_like "a sync controller that authenticates user requests"
  it_behaves_like "a sync controller that audits the data access"

  describe "POST sync: send data from device to server;" do
    it_behaves_like "a working sync controller creating records"
    it_behaves_like "a working sync controller updating records"

    context "handles appointment_type correctly" do
      before :each do
        set_authentication_headers
      end

      describe "stores appointment_type correctly" do
        let(:request_key) { model.to_s.underscore.pluralize }
        let(:new_records) { (1..3).map { build_payload.call } }
        let(:new_records_payload) { Hash[request_key, new_records] }

        it "creates new records with appointment_type" do
          post(:sync_from_user, params: new_records_payload, as: :json)

          expect(response).to have_http_status(200)

          after_post_appointments = Appointment.all
          after_post_appointments_ids = after_post_appointments.map(&:id)

          new_records.each do |record|
            expect(after_post_appointments_ids.include?(record[:id])).to be true
            expect(Appointment.appointment_types.include?(record[:appointment_type])).to be true
          end
        end

        it "returns an error for new records without appointment_type" do
          records_with_no_appointment_type = (1..3).map { build_payload.call.except(:appointment_type) }
          records_payload_with_no_appointment_type = Hash[request_key, records_with_no_appointment_type]

          post(:sync_from_user, params: records_payload_with_no_appointment_type, as: :json)

          expect(response).to have_http_status(200)
          errors = JSON(response.body)["errors"]
          errors.each do |error|
            expect(error["schema"].first).to match(/did not contain a required property of 'appointment_type' in schema/)
          end
        end

        it "defaults the creation_facility to the facility_id if creation_facility is not a part of the payload" do
          records_with_no_creation_facility = (1..3).map { build_payload.call.except(:creation_facility_id) }
          records_payload_with_no_creation_facility = Hash[request_key, records_with_no_creation_facility]

          post(:sync_from_user, params: records_payload_with_no_creation_facility, as: :json)
          expect(response).to have_http_status(200)

          Appointment.all.each do |a|
            expect(a.creation_facility_id).to eq(a.facility_id)
          end
        end

        it "returns an error for new records with invalid appointment type" do
          records_with_invalid_appointment_type = (1..3).map { build_payload.call }
          records_with_invalid_appointment_type.each do |record|
            record[:appointment_type] = %w[manuall automat foo].sample
          end

          records_payload_with_bad_appointment_type = Hash[request_key, records_with_invalid_appointment_type]

          post(:sync_from_user, params: records_payload_with_bad_appointment_type, as: :json)

          errors = JSON(response.body)["errors"]
          errors.each do |error|
            expect(error["schema"].first).to match(/did not match one of the following values: manual, automatic in schema/)
          end
        end
      end
    end
  end

  describe "GET sync: send data from server to device;" do
    it_behaves_like "a working V3 sync controller sending records"

    context "patient prioritisation" do
      it "syncs records for patients in the request facility first" do
        request_2_facility = create(:facility, facility_group: request_facility_group)
        create_record_list(2, facility: request_facility, updated_at: 3.minutes.ago)
        create_record_list(2, facility: request_facility, updated_at: 5.minutes.ago)
        create_record_list(2, facility: request_2_facility, updated_at: 7.minutes.ago)
        create_record_list(2, facility: request_2_facility, updated_at: 10.minutes.ago)

        # GET request 1
        set_authentication_headers
        get :sync_to_user, params: {limit: 4}
        response_1_body = JSON(response.body)

        response_1_record_ids = response_1_body["appointments"].map { |r| r["id"] }
        response_1_records = model.where(id: response_1_record_ids)
        expect(response_1_records.count).to eq 4
        expect(response_1_records.map(&:facility).to_set).to eq Set[request_facility]

        # GET request 2
        get :sync_to_user, params: {limit: 4, process_token: response_1_body["process_token"]}
        response_2_body = JSON(response.body)

        response_2_record_ids = response_2_body["appointments"].map { |r| r["id"] }
        response_2_records = model.where(id: response_2_record_ids)
        expect(response_2_records.count).to eq 4
        expect(response_2_records.map(&:facility).to_set).to eq Set[request_facility, request_2_facility]
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
      let(:patient_in_another_block) { create(:patient, :without_medical_history, registration_facility: facility_in_another_block) }
      let(:patient_in_another_facility_group) { create(:patient, :without_medical_history, registration_facility: facility_in_another_group) }

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
            *create_list(:appointment, 2, patient: patient_in_request_facility, facility: request_facility),
            *create_list(:appointment, 2, patient: patient_in_same_block, facility: facility_in_same_block)
          ]

          not_expected_records = [
            *create_list(:appointment, 2, patient: patient_in_another_block, facility: facility_in_another_block),
            *create_list(:medical_history, 2, patient: patient_in_another_facility_group)
          ]

          get :sync_to_user

          response_records = JSON(response.body)["appointments"]
          response_records.each { |r| expect(r["id"]).to be_in(expected_records.map(&:id)) }
          response_records.each { |r| expect(r["id"]).to_not be_in(not_expected_records.map(&:id)) }
        end
      end

      context "region-level sync is turned off" do
        it "defaults to sending data for patients in the user's facility group" do
          expected_records = [
            *create_list(:appointment, 2, patient: patient_in_request_facility, facility: request_facility),
            *create_list(:appointment, 2, patient: patient_in_same_block, facility: facility_in_same_block),
            *create_list(:appointment, 2, patient: patient_in_another_block, facility: facility_in_another_block)
          ]

          not_expected_records =
            create_list(:appointment, 2, patient: patient_in_another_facility_group, facility: facility_in_another_group)

          get :sync_to_user

          response_records = JSON(response.body)["appointments"]
          response_records.each { |r| expect(r["id"]).to be_in(expected_records.map(&:id)) }
          response_records.each { |r| expect(r["id"]).to_not be_in(not_expected_records.map(&:id)) }
        end
      end
    end

    context "handles appointment_type correctly" do
      before :each do
        set_authentication_headers
        create_list(:appointment, 2, facility: request_facility)
      end

      describe "retrieves appointment_type correctly" do
        it "retrieves new records with appointment_type" do
          get :sync_to_user, params: {limit: 15}

          response_appointments = JSON(response.body)["appointments"]

          response_appointments.each do |appointment|
            expect(Appointment.appointment_types.include?(appointment["appointment_type"])).to be true
          end
        end
      end
    end
  end
end
