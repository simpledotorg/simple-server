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
        let(:new_records_payload) { {request_key => new_records} }

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
          records_payload_with_no_appointment_type = {request_key => records_with_no_appointment_type}

          post(:sync_from_user, params: records_payload_with_no_appointment_type, as: :json)

          expect(response).to have_http_status(200)
          errors = JSON(response.body)["errors"]
          errors.each do |error|
            expect(error["schema"].first).to match(/did not contain a required property of 'appointment_type' in schema/)
          end
        end

        it "defaults the creation_facility to the facility_id if creation_facility is not a part of the payload" do
          records_with_no_creation_facility = (1..3).map { build_payload.call.except(:creation_facility_id) }
          records_payload_with_no_creation_facility = {request_key => records_with_no_creation_facility}

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

          records_payload_with_bad_appointment_type = {request_key => records_with_invalid_appointment_type}

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

    context "region-level sync" do
      let!(:response_key) { model.to_s.underscore.pluralize }
      let!(:facility_in_same_block) {
        create(:facility, state: request_facility.state, block: request_facility.block, facility_group: request_facility_group)
      }

      let!(:facility_in_other_block) {
        create(:facility, block: "Other Block", facility_group: request_facility_group)
      }

      let!(:facility_in_other_group) {
        create(:facility, facility_group: create(:facility_group))
      }

      let!(:patient_in_request_facility) { create(:patient, :without_medical_history, registration_facility: request_facility) }
      let!(:patient_in_same_block) { create(:patient, :without_medical_history, registration_facility: facility_in_same_block) }
      let!(:patient_assigned_to_block) { create(:patient, :without_medical_history, assigned_facility: facility_in_same_block) }
      let!(:patient_in_other_block) { create(:patient, :without_medical_history, registration_facility: facility_in_other_block) }
      let!(:patient_in_other_facility_group) { create(:patient, :without_medical_history, registration_facility: facility_in_other_group) }

      before { set_authentication_headers }

      context "region-level sync" do
        context "when X_SYNC_REGION_ID is blank (support for old apps)" do
          it "sends facility group records irrespective of process_token's sync_region_id" do
            facility_group_records = [
              *create_record_list(2, patient: patient_in_request_facility, facility: request_facility),
              *create_record_list(2, patient: patient_in_same_block, facility: facility_in_same_block),
              *create_record_list(2, patient: patient_in_other_block, facility: facility_in_other_block)
            ]

            other_facility_group_records =
              create_record_list(2, patient: patient_in_other_facility_group, facility: facility_in_other_group)

            process_token_sync_region_ids = [nil, request_facility.region.block_region.id, request_facility.facility_group_id]

            process_token_sync_region_ids.each do |process_token_sync_region_id|
              process_token = make_process_token(sync_region_id: process_token_sync_region_id)

              get :sync_to_user, params: {process_token: process_token}

              response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
              expect(response_record_ids).to match_array facility_group_records.map(&:id)
              expect(other_facility_group_records).not_to include(*response_record_ids)
            end
          end
        end

        context "when X_SYNC_REGION_ID is current_facility_group_id" do
          before { request.env["HTTP_X_SYNC_REGION_ID"] = request_facility_group.id }

          context "when process_token's sync_region_id is empty" do
            it "syncs facility group records" do
              facility_group_records = [
                *create_record_list(2, patient: patient_in_request_facility, facility: request_facility),
                *create_record_list(2, patient: patient_in_same_block, facility: facility_in_same_block),
                *create_record_list(2, patient: patient_in_other_block, facility: facility_in_other_block)
              ]

              other_facility_group_records =
                create_record_list(2, patient: patient_in_other_facility_group, facility: facility_in_other_group)

              get :sync_to_user

              response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
              expect(response_record_ids).to match_array facility_group_records.map(&:id)
              expect(other_facility_group_records).not_to include(*response_record_ids)
            end
          end

          context "when process_token's sync_region_id is current_facility_group_id (i.e. app starts syncing)" do
            it "syncs facility group records" do
              process_token = make_process_token(sync_region_id: request_facility_group.id)
              facility_group_records = [
                *create_record_list(2, patient: patient_in_request_facility, facility: request_facility),
                *create_record_list(2, patient: patient_in_same_block, facility: facility_in_same_block),
                *create_record_list(2, patient: patient_in_other_block, facility: facility_in_other_block)
              ]

              other_facility_group_records =
                create_record_list(2, patient: patient_in_other_facility_group, facility: facility_in_other_group)

              get :sync_to_user, params: {process_token: process_token}

              response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
              expect(response_record_ids).to match_array facility_group_records.map(&:id)
              expect(other_facility_group_records).not_to include(*response_record_ids)
            end
          end

          context "when process_token is block_id (this can happen if we switch from block sync to FG sync)" do
            it "force resyncs facility_group records" do
              process_token = make_process_token(sync_region_id: request_facility.region.block_region.id,
                current_facility_processed_since: Time.current,
                other_facilities_processed_since: Time.current)
              Timecop.travel(15.minutes.ago) { create_record_list(10) }

              get :sync_to_user, params: {process_token: process_token}

              response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
              expect(response_record_ids).to match_array Appointment.pluck(:id)
            end
          end
        end

        context "when X_SYNC_REGION_ID is block_id" do
          before { request.env["HTTP_X_SYNC_REGION_ID"] = request_facility.region.block_region.id }

          context "when process_token's sync_region_id is empty (i.e. app starts syncing)" do
            it "syncs data belonging to the patients in the block of user's facility" do
              block_records = [
                *create_record_list(2, patient: patient_in_request_facility, facility: request_facility),
                *create_record_list(2, patient: patient_in_same_block, facility: facility_in_same_block),
                *create_record_list(2, patient: patient_assigned_to_block, facility: facility_in_same_block)
              ]

              non_block_records = [
                *create_record_list(2, patient: patient_in_other_block, facility: facility_in_other_block),
                *create_record_list(2, patient: patient_in_other_facility_group)
              ]

              get :sync_to_user

              response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
              expect(response_record_ids).to match_array block_records.map(&:id)
              expect(non_block_records).not_to include(*response_record_ids)
            end
          end

          context "when process_token's sync_region_id is current_facility_group_id" do
            it "force resyncs block records" do
              process_token = make_process_token(sync_region_id: request_facility_group.id,
                current_facility_processed_since: Time.current,
                other_facilities_processed_since: Time.current)
              block_records = Timecop.travel(15.minutes.ago) {
                [*create_record_list(10, patient: patient_in_same_block, facility: facility_in_same_block)]
              }
              non_block_records = Timecop.travel(15.minutes.ago) { create_record_list(2, facility: facility_in_other_block) }

              get :sync_to_user, params: {process_token: process_token}

              response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
              expect(response_record_ids).to match_array block_records.map(&:id)
              expect(non_block_records).not_to include(*response_record_ids)
            end
          end

          context "when process_token's sync_region_id is block_id (when we switch from FG sync to block level sync)" do
            it "syncs data belonging to the patients in the block of user's facility" do
              process_token = make_process_token(sync_region_id: request_facility.region.block_region.id)

              block_records = [
                *create_record_list(2, patient: patient_in_request_facility, facility: request_facility),
                *create_record_list(2, patient: patient_in_same_block, facility: facility_in_same_block),
                *create_record_list(2, patient: patient_assigned_to_block, facility: facility_in_same_block)
              ]

              non_block_records = [
                *create_record_list(2, patient: patient_in_other_block, facility: facility_in_other_block),
                *create_record_list(2, patient: patient_in_other_facility_group)
              ]

              get :sync_to_user, params: {process_token: process_token}

              response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
              expect(response_record_ids).to match_array block_records.map(&:id)
              expect(non_block_records).not_to include(*response_record_ids)
            end
          end
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
