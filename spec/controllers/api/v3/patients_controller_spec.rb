require "rails_helper"

RSpec.describe Api::V3::PatientsController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { Patient }
  let(:patient_metadata) { {registration_facility_id: request_facility.id, assigned_facility_id: request_facility.id} }
  let(:build_payload) { ->(patient = build(:patient)) { build_patient_payload(patient).merge(patient_metadata) } }
  let(:build_invalid_payload) { -> { build_invalid_patient_payload } }
  let(:update_payload) { ->(record) { updated_patient_payload record } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:number_of_schema_errors_in_invalid_payload) { 2 + invalid_record["phone_numbers"].count }

  def create_record(options = {})
    facility = create(:facility, facility_group: request_facility_group)
    create(:patient, options.merge(registration_facility: facility))
  end

  def create_record_list(n, options = {})
    facility = create(:facility, facility_group: request_facility_group)
    create_list(:patient, n, options.merge(registration_facility: facility))
  end

  it_behaves_like "a sync controller that authenticates user requests"
  it_behaves_like "a sync controller that audits the data access"

  describe "POST sync: send data from device to server;" do
    it_behaves_like "a working sync controller creating records"

    describe "creates new patients" do
      before :each do
        request.env["HTTP_X_USER_ID"] = request_user.id
        request.env["HTTP_X_FACILITY_ID"] = request_facility.id
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
      end

      it "creates new patients" do
        patients = (1..3).map { build_payload.call }
        post(:sync_from_user, params: {patients: patients}, as: :json)

        expect(Patient.count).to eq 3
        expect(Address.count).to eq 3
        expect(PatientPhoneNumber.count).to eq(patients.sum { |patient| patient["phone_numbers"].count })
        expect(response).to have_http_status(200)
      end

      it "sets the recorded_at sent in the params" do
        time = Time.current
        patient = FactoryBot.build(:patient, recorded_at: time)
        patient_payload = build_payload.call(patient)
        post(:sync_from_user, params: {patients: [patient_payload]}, as: :json)

        patient_in_db = Patient.find(patient.id)
        expect(patient_in_db.recorded_at.to_i).to eq(time.to_i)
      end

      context "registration_facility_id param is available" do
        it "sets it on the patient" do
          new_registration_facility = create(:facility, facility_group: request_facility_group)
          patient = FactoryBot.build(:patient, registration_facility: new_registration_facility)
          patient_payload = build_patient_payload(patient)

          post :sync_from_user, params: {patients: [patient_payload]}, as: :json

          expect(response).to have_http_status(200)
          expect(Patient.first.registration_facility).to eq new_registration_facility
        end
      end

      context "registration_facility_id param is missing" do
        it "picks up the registration_facility_id from the headers" do
          new_registration_facility = create(:facility, facility_group: request_facility_group)
          request.env["HTTP_X_FACILITY_ID"] = new_registration_facility.id
          patient = FactoryBot.build(:patient)
          patient_payload = build_payload.call(patient).except(:registration_facility_id)

          post :sync_from_user, params: {patients: [patient_payload]}, as: :json

          expect(response).to have_http_status(200)
          expect(Patient.first.registration_facility).to eq new_registration_facility
        end
      end

      context "recorded_at is not sent" do
        it "defaults recorded_at to device_created_at" do
          patient = FactoryBot.build(:patient)
          patient_payload = build_payload.call(patient).except("recorded_at")
          post(:sync_from_user, params: {patients: [patient_payload]}, as: :json)

          patient_in_db = Patient.find(patient.id)
          expect(patient_in_db.recorded_at.to_i).to eq(patient_in_db.device_created_at.to_i)
        end

        it "sets recorded_at to the earliest bp's recorded_at in case patient is synced later" do
          patient = FactoryBot.build(:patient)
          blood_pressure_recorded_at = 1.month.ago
          create(:blood_pressure,
            patient_id: patient.id,
            recorded_at: blood_pressure_recorded_at)

          patient_payload = build_payload.call(patient).except("recorded_at")
          post :sync_from_user, params: {patients: [patient_payload]}, as: :json

          patient_in_db = Patient.find(patient.id)
          expect(patient_in_db.recorded_at.to_i).to eq(blood_pressure_recorded_at.to_i)
        end
      end

      it "creates new patients without address" do
        post(:sync_from_user, params: {patients: [build_payload.call.except("address")]}, as: :json)
        expect(Patient.count).to eq 1
        expect(Address.count).to eq 0
        expect(response).to have_http_status(200)
      end

      it "creates new patients without phone numbers" do
        post(:sync_from_user, params: {patients: [build_payload.call.except("phone_numbers")]}, as: :json)
        expect(Patient.count).to eq 1
        expect(PatientPhoneNumber.count).to eq 0
        expect(response).to have_http_status(200)
      end

      it "creates new patients without business identifiers" do
        post(:sync_from_user, params: {patients: [build_payload.call.except("business_identifiers")]}, as: :json)
        expect(Patient.count).to eq 1
        expect(PatientBusinessIdentifier.count).to eq 0
        expect(response).to have_http_status(200)
      end

      it "associates registration user with the patients" do
        post(:sync_from_user, params: {patients: [build_payload.call.except("phone_numbers")]}, as: :json)
        expect(response).to have_http_status(200)
        expect(Patient.count).to eq 1
        expect(Patient.first.registration_user).to eq request_user
      end
    end

    describe "updates patients" do
      before :each do
        request.env["HTTP_X_USER_ID"] = request_user.id
        request.env["HTTP_X_FACILITY_ID"] = request_facility.id
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
      end

      let(:existing_patients) { create_list(:patient, 3, patient_metadata) }
      let(:updated_patients_payload) { existing_patients.map { |patient| updated_patient_payload(patient) } }

      it "with only updated patient attributes" do
        patients_payload = updated_patients_payload.map { |patient|
          patient.except("address", "phone_numbers", "business_identifiers")
        }
        post :sync_from_user, params: {patients: patients_payload}, as: :json

        patients_payload.each do |updated_patient|
          db_patient = Patient.find(updated_patient["id"])
          expect(db_patient.attributes.with_payload_keys.with_int_timestamps
                   .except("address_id")
                   .except("registration_user_id")
                   .except("test_data")
                   .except("deleted_by_user_id"))
            .to eq(updated_patient.with_int_timestamps)
        end
      end

      it "with only updated address" do
        patients_payload = updated_patients_payload.map { |patient| patient.except("phone_numbers") }
        post :sync_from_user, params: {patients: patients_payload}, as: :json

        patients_payload.each do |updated_patient|
          db_patient = Patient.find(updated_patient["id"])
          expect(db_patient.address.attributes.with_payload_keys.with_int_timestamps)
            .to eq(updated_patient["address"].with_int_timestamps)
        end
      end

      it "with only updated phone numbers" do
        patients_payload = updated_patients_payload.map { |patient| patient.except("address") }
        sync_time = Time.current
        post :sync_from_user, params: {patients: patients_payload}, as: :json

        expect(PatientPhoneNumber.updated_on_server_since(sync_time).count).to eq 3
        patients_payload.each do |updated_patient|
          updated_phone_number = updated_patient["phone_numbers"].first
          db_phone_number = PatientPhoneNumber.find(updated_phone_number["id"])
          expect(db_phone_number.attributes.with_payload_keys.with_int_timestamps)
            .to eq(updated_phone_number.with_int_timestamps)
        end
      end

      context "with all attributes and associations updated" do
        let!(:patients_payload) { updated_patients_payload }
        let!(:sync_time) { Time.current }

        before do
          post :sync_from_user, params: {patients: patients_payload}, as: :json
        end

        it "updates non-nested fields" do
          patients_payload.each do |updated_patient|
            updated_patient.with_int_timestamps
            db_patient = Patient.find(updated_patient["id"])
            expect(db_patient.attributes.with_payload_keys.with_int_timestamps
                     .except("address_id")
                     .except("registration_user_id")
                     .except("test_data")
                     .except("deleted_by_user_id"))
              .to eq(updated_patient.except("address", "phone_numbers", "business_identifiers"))
          end
        end

        it "updates address" do
          patients_payload.each do |updated_patient|
            updated_patient.with_int_timestamps
            db_patient = Patient.find(updated_patient["id"])

            expect(db_patient.address.attributes.with_payload_keys.with_int_timestamps)
              .to eq(updated_patient["address"])
          end
        end

        it "updates phone numbers" do
          expect(PatientPhoneNumber.updated_on_server_since(sync_time).count).to eq 3

          patients_payload.each do |updated_patient|
            updated_phone_number = updated_patient["phone_numbers"].first
            db_phone_number = PatientPhoneNumber.find(updated_phone_number["id"])

            expect(db_phone_number.attributes.with_payload_keys.with_int_timestamps)
              .to eq(updated_phone_number.with_int_timestamps)
          end
        end

        it "updates business identifiers" do
          expect(PatientBusinessIdentifier.updated_on_server_since(sync_time).count).to eq 3

          patients_payload.each do |updated_patient|
            updated_business_identifier = updated_patient["business_identifiers"].first.with_int_timestamps
            if updated_business_identifier[:metadata].present?
              updated_business_identifier_metadata = JSON.parse(updated_business_identifier[:metadata])
            end
            db_business_identifier = PatientBusinessIdentifier.find(updated_business_identifier["id"])

            expect(db_business_identifier.attributes.with_payload_keys.with_int_timestamps)
              .to eq(updated_business_identifier.merge("metadata" => updated_business_identifier_metadata))
          end
        end
      end

      context "patient business_identifier" do
        it "disallows missing identifier for bangladesh_national_id" do
          patients_payload = build_payload.call(create(:patient))
          business_identifier = build_business_identifier_payload
          business_identifier.delete("identifier")
          payload_without_biz_id = patients_payload.deep_merge("business_identifiers" => [business_identifier])

          post :sync_from_user, params: {patients: [payload_without_biz_id]}, as: :json

          expect(response).to have_http_status(200)
          # Nested errors are not currently reported, so the response errors map doesn't contain an error
          # Checking if the PatientBusinessIdentifier got created instead
          expect(JSON.parse(response.body)["errors"].to_s).to match(/business_identifiers\/0/)
          expect(PatientBusinessIdentifier.where(id: business_identifier["id"]).count).to eq 0
        end
      end

      it "does not change registration user or facility" do
        current_user = create(:user)
        current_facility = create(:facility, facility_group: current_user.facility.facility_group)
        request.env["HTTP_X_USER_ID"] = current_user.id
        request.env["HTTP_X_FACILITY_ID"] = current_facility.id
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{current_user.access_token}"

        patients_payload = updated_patients_payload

        previous_registration_user_id = Patient.first.registration_user_id
        previous_registration_facility_id = Patient.first.registration_facility_id

        post :sync_from_user, params: {patients: patients_payload}, as: :json

        expect(response).to have_http_status(200)
        patient = Patient.first
        expect(patient.registration_user.id).to eq previous_registration_user_id
        expect(patient.registration_facility.id).to eq previous_registration_facility_id
        expect(patient.registration_user.id).to_not eq current_user.id
        expect(patient.registration_facility.id).to_not eq current_facility.id
      end
    end

    describe "soft deletes patients" do
      before :each do
        request.env["HTTP_X_USER_ID"] = request_user.id
        request.env["HTTP_X_FACILITY_ID"] = request_facility.id
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
      end

      let(:existing_patient) { create(:patient) }
      let(:deleted_time) { Time.current }
      let(:delete_patient_payload) do
        build_payload.call(existing_patient)
          .merge(
            deleted_at: deleted_time,
            updated_at: deleted_time,
            deleted_reason: "duplicate"
          )
      end

      it "deletes a patient when the patient payload has the deleted_at field set" do
        expect(Patient.find(existing_patient.id)).to be_present
        post :sync_from_user, params: {patients: [delete_patient_payload]}, as: :json

        expect(Patient.find_by(id: existing_patient.id)).to be_nil
        expect(Patient.with_discarded.find_by(id: existing_patient.id)).to be_present
      end

      it "sets the patient's deleted_reason and deleted_user_id" do
        expect(Patient.find(existing_patient.id)).to be_present
        post :sync_from_user, params: {patients: [delete_patient_payload]}, as: :json

        expect(Patient.with_discarded.find_by(id: existing_patient.id).deleted_reason).to eq("duplicate")
        expect(Patient.with_discarded.find_by(id: existing_patient.id).deleted_by_user_id).to eq(request_user.id)
      end

      it "doesn't update soft deleted patient's attributes" do
        existing_patient_name = existing_patient.full_name

        existing_patient.discard_data

        update_payload_for_discarded_patient =
          build_payload.call(existing_patient).merge(full_name: "Test Patient Name Xcad7asd")

        post :sync_from_user, params: {patients: [update_payload_for_discarded_patient]}, as: :json

        expect(Patient.with_discarded.find_by(id: existing_patient.id).full_name).to eq(existing_patient_name)
      end
    end
  end

  describe "GET sync: send data from server to device;" do
    it_behaves_like "a working V3 sync controller sending records"

    context "facility prioritisation" do
      it "syncs request facility's records first" do
        request_2_facility = create(:facility, facility_group: request_facility_group)
        create_list(:patient, 2, registration_facility: request_2_facility, updated_at: 3.minutes.ago)
        create_list(:patient, 2, registration_facility: request_2_facility, updated_at: 5.minutes.ago)
        create_list(:patient, 2, registration_facility: request_facility, updated_at: 7.minutes.ago)
        create_list(:patient, 2, registration_facility: request_facility, updated_at: 10.minutes.ago)

        # GET request 1
        set_authentication_headers
        get :sync_to_user, params: {limit: 4}
        response_1_body = JSON(response.body)

        record_ids = response_1_body["patients"].map { |r| r["id"] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:registration_facility).to_set).to eq Set[request_facility]

        # GET request 2
        get :sync_to_user, params: {limit: 4, process_token: response_1_body["process_token"]}
        response_2_body = JSON(response.body)

        record_ids = response_2_body["patients"].map { |r| r["id"] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:registration_facility).to_set).to eq Set[request_facility, request_2_facility]
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
      let(:process_token) { Base64.encode64({sync_region_id: request_facility.region.block.id}.to_json) }

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

        it "only sends patients in the block of user's facility" do
          expected_records = [patient_in_request_facility, patient_in_same_block, patient_assigned_to_block, patient_with_appointment_in_block]
          not_expected_records = [patient_in_another_block, patient_in_another_facility_group]

          get :sync_to_user, params: {process_token: process_token}

          response_records = JSON(response.body)["patients"]
          response_records.each { |r| expect(r["id"]).to be_in(expected_records.map(&:id)) }
          response_records.each { |r| expect(r["id"]).to_not be_in(not_expected_records.map(&:id)) }
        end
      end

      context "region-level sync is turned off" do
        it "defaults to sending patients in the user's facility group" do
          expected_records = [patient_in_request_facility, patient_in_same_block, patient_in_another_block]
          not_expected_records = [patient_in_another_facility_group]

          get :sync_to_user, params: {process_token: process_token}

          response_records = JSON(response.body)["patients"]
          response_records.each { |r| expect(r["id"]).to be_in(expected_records.map(&:id)) }
          response_records.each { |r| expect(r["id"]).to_not be_in(not_expected_records.map(&:id)) }
        end
      end
    end
  end
end
