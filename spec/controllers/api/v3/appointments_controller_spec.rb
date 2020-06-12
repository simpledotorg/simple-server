require "rails_helper"

RSpec.describe Api::V3::AppointmentsController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }
  let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
  before :each do
    request.env["X_USER_ID"] = request_user.id
    request.env["X_FACILITY_ID"] = request_facility.id
    request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
  end

  let(:model) { Appointment }

  let(:build_payload) { -> { build_appointment_payload } }
  let(:build_invalid_payload) { -> { build_invalid_appointment_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { ->(appointment) { updated_appointment_payload appointment } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  def create_record(options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    FactoryBot.create(:appointment, options.merge(facility: facility))
  end

  def create_record_list(n, options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    FactoryBot.create_list(:appointment, n, options.merge(facility: facility))
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

    describe "v3 facility prioritisation" do
      it "syncs request facility's records first" do
        request_2_facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
        FactoryBot.create_list(:appointment, 2, facility: request_2_facility, updated_at: 3.minutes.ago)
        FactoryBot.create_list(:appointment, 2, facility: request_2_facility, updated_at: 5.minutes.ago)
        FactoryBot.create_list(:appointment, 2, facility: request_facility, updated_at: 7.minutes.ago)
        FactoryBot.create_list(:appointment, 2, facility: request_facility, updated_at: 10.minutes.ago)

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

    describe "syncing within a facility group" do
      let(:facility_in_same_group) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
      let(:facility_in_another_group) { FactoryBot.create(:facility) }

      before :each do
        set_authentication_headers
        FactoryBot.create_list(:appointment, 2, facility: facility_in_another_group, updated_at: 3.minutes.ago)
        FactoryBot.create_list(:appointment, 2, facility: facility_in_same_group, updated_at: 5.minutes.ago)
        FactoryBot.create_list(:appointment, 2, facility: request_facility, updated_at: 7.minutes.ago)
      end

      it "only sends data for facilities belonging in the sync group of user's registration facility" do
        get :sync_to_user, params: {limit: 15}

        response_appointments = JSON(response.body)["appointments"]
        response_facilities = response_appointments.map { |appointment| appointment["facility_id"] }.to_set

        expect(response_facilities).to match_array([request_facility.id, facility_in_same_group.id])
        expect(response_facilities).not_to include(facility_in_another_group.id)
      end
    end

    context "handles appointment_type correctly" do
      before :each do
        set_authentication_headers
        FactoryBot.create_list(:appointment, 2, facility: request_facility)
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
