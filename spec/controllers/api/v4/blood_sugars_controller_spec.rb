# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V4::BloodSugarsController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { BloodSugar }
  let(:build_payload) { -> { build_blood_sugar_payload } }
  let(:build_invalid_payload) { -> { build_invalid_blood_sugar_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { ->(blood_sugar) { updated_blood_sugar_payload(blood_sugar) } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  before :each do
    request.env["X_USER_ID"] = request_user.id
    request.env["X_FACILITY_ID"] = request_facility.id
    request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
  end

  def create_record(options = {})
    facility = options[:facility] || create(:facility, facility_group: request_facility_group)
    patient = create(:patient, registration_facility: facility)
    create(:blood_sugar, :with_encounter, {patient: patient}.merge(options))
  end

  def create_record_list(n, options = {})
    facility = options[:facility] || create(:facility, facility_group: request_facility_group)
    patient = create(:patient, registration_facility: facility)
    create_list(:blood_sugar, n, :with_encounter, {patient: patient}.merge(options))
  end

  it_behaves_like "a sync controller that authenticates user requests"
  it_behaves_like "a sync controller that audits the data access"

  describe "POST sync: send data from device to server;" do
    it_behaves_like "a working sync controller creating records"

    describe "a working sync controller updating records" do
      let(:request_key) { model.to_s.underscore.pluralize }
      let(:existing_records) { create_record_list(10) }
      let(:updated_records) { existing_records.map(&update_payload) }
      let(:updated_payload) { {request_key => updated_records} }

      before :each do
        set_authentication_headers
      end

      describe "updates records" do
        it "with updated record attributes" do
          post :sync_from_user, params: updated_payload, as: :json

          updated_records.each do |record|
            db_record = model.find(record["id"])
            expect(db_record.attributes.with_payload_keys.with_int_timestamps)
              .to eq(record.to_json_and_back.with_int_timestamps)
          end
        end
      end
    end

    describe "creates new blood sugars" do
      before :each do
        request.env["HTTP_X_USER_ID"] = request_user.id
        request.env["HTTP_X_FACILITY_ID"] = request_facility.id
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
      end

      it "creates new blood sugars with associated patient" do
        patient = create(:patient)
        blood_sugars = (1..3).map {
          build_blood_sugar_payload(build(:blood_sugar, patient: patient))
        }
        post(:sync_from_user, params: {blood_sugars: blood_sugars}, as: :json)
        expect(BloodSugar.count).to eq 3
        expect(patient.blood_sugars.count).to eq 3
        expect(response).to have_http_status(200)
      end

      context "recorded_at is sent" do
        it "sets the recorded_at sent in the params" do
          recorded_at = 1.month.ago
          blood_sugar = build_blood_sugar_payload(build(:blood_sugar, recorded_at: recorded_at))

          post(:sync_from_user, params: {blood_sugars: [blood_sugar]}, as: :json)

          blood_sugar = BloodSugar.find(blood_sugar["id"])
          expect(blood_sugar.recorded_at.to_i).to eq(recorded_at.to_i)
        end

        it "does not modify the recorded_at for a patient if params have recorded_at" do
          patient_recorded_at = 4.months.ago
          patient = create(:patient, recorded_at: patient_recorded_at)
          older_blood_sugar_recording_date = 5.months.ago
          blood_sugar = build_blood_sugar_payload(build(:blood_sugar,
            patient: patient,
            recorded_at: older_blood_sugar_recording_date))
          post(:sync_from_user, params: {blood_sugars: [blood_sugar]}, as: :json)

          patient.reload
          expect(patient.recorded_at.to_i).to eq(patient_recorded_at.to_i)
        end
      end

      context "hba1c blood sugars" do
        it "successfully records hba1c blood sugars" do
          blood_sugar = build_blood_sugar_payload(build(:blood_sugar, blood_sugar_type: :hba1c))

          post(:sync_from_user, params: {blood_sugars: [blood_sugar]}, as: :json)
          errors = JSON(response.body)["errors"]

          expect(response).to have_http_status(200)
          expect(errors).to eq([])
          expect(BloodSugar.find(blood_sugar["id"]).blood_sugar_value).to eq blood_sugar["blood_sugar_value"]
          expect(BloodSugar.find(blood_sugar["id"]).blood_sugar_type).to eq blood_sugar["blood_sugar_type"]
        end
      end

      context "creates encounters" do
        it "assumes the same encounter for the blood_sugars recorded on the same day" do
          patient = create(:patient)

          blood_sugar_recording = Time.new(2019, 1, 1, 1, 1).utc
          encountered_on = blood_sugar_recording.to_date

          blood_sugars = (1..3).map {
            build(:blood_sugar,
              facility: request_facility,
              patient: patient,
              recorded_at: blood_sugar_recording)
          }

          blood_sugars_payload = blood_sugars.map(&method(:build_blood_sugar_payload))

          expect {
            post(:sync_from_user, params: {blood_sugars: blood_sugars_payload}, as: :json)
          }.to change { Encounter.count }.by(1)
          expect(response).to have_http_status(200)
          expect(Encounter.pluck(:encountered_on)).to contain_exactly(encountered_on)
          expected_blood_sugars_thru_encounters = Encounter.all.flat_map(&:blood_sugars)
          expect(expected_blood_sugars_thru_encounters).to match_array(BloodSugar.where(id: blood_sugars.pluck(:id)))
        end

        it "should create different encounters for blood_sugars recorded on different days" do
          patient = create(:patient)

          day_1 = Time.new(2019, 1, 1, 1, 1).utc
          day_2 = Time.new(2019, 1, 2, 1, 1).utc
          day_3 = Time.new(2019, 1, 3, 1, 1).utc

          encountered_on_1 = day_1.to_date
          encountered_on_2 = day_2.to_date
          encountered_on_3 = day_3.to_date

          blood_sugars = [day_1, day_2, day_3].map { |date|
            build(:blood_sugar,
              facility: request_facility,
              patient: patient,
              recorded_at: date)
          }

          _add_blood_sugars = create_list(:blood_sugar, 5)

          blood_sugars_payload = blood_sugars.map(&method(:build_blood_sugar_payload))

          expect {
            post(:sync_from_user, params: {blood_sugars: blood_sugars_payload}, as: :json)
          }.to change { Encounter.count }.by(3)
          expect(response).to have_http_status(200)
          expect(Encounter.pluck(:encountered_on)).to contain_exactly(encountered_on_1,
            encountered_on_2,
            encountered_on_3)
          expected_blood_sugars_thru_encounters = Encounter.all.flat_map(&:blood_sugars)
          expect(expected_blood_sugars_thru_encounters).to match_array(BloodSugar.where(id: blood_sugars.pluck(:id)))
        end

        it "should create different encounters for Blood Sugars recorded against different date, patient or facility" do
          day_1 = Time.new(2019, 1, 1, 1, 1).utc
          day_2 = Time.new(2019, 1, 2, 1, 1).utc
          day_3 = Time.new(2019, 1, 3, 1, 1).utc

          range_of_possible_observations = (0..rand * 10).to_a

          blood_sugars = [day_1, day_2, day_3].flat_map { |date|
            patient = create(:patient)
            facility = create(:facility)

            range_of_possible_observations.map do
              build(:blood_sugar,
                facility: facility,
                patient: patient,
                recorded_at: date)
            end
          }

          blood_sugars_payload = blood_sugars.map(&method(:build_blood_sugar_payload))

          expect {
            post(:sync_from_user, params: {blood_sugars: blood_sugars_payload}, as: :json)
          }.to change { Encounter.count }.by(3)
          expect(response).to have_http_status(200)
          expect(Encounter.all.flat_map(&:blood_sugars).count).to eq(range_of_possible_observations.count * 3)
        end
      end

      context "existing encounter" do
        let!(:blood_pressure) { create(:blood_pressure) }
        let!(:encounter_id) { Encounter.generate_id(blood_pressure.facility_id, blood_pressure.patient_id, blood_pressure.recorded_at.to_date) }
        let!(:encounter) { create(:encounter, :with_observables, id: encounter_id, observable: blood_pressure) }
        let!(:blood_sugar_payload) do
          build_blood_sugar_payload(
            build(:blood_sugar,
              patient: blood_pressure.patient,
              facility: blood_pressure.facility,
              recorded_at: blood_pressure.recorded_at)
          )
        end

        it "adds the blood sugar to an existing encounter" do
          expect {
            post(:sync_from_user, params: {blood_sugars: [blood_sugar_payload]}, as: :json)
          }.not_to change { Encounter.count }

          encounter.reload

          expect(encounter.blood_sugars.first.id).to eq(blood_sugar_payload[:id])
        end
      end
    end

    context "for a discarded facility" do
      before :each do
        set_authentication_headers
      end

      it "returns an error and does not create the blood sugar" do
        facility = create(:facility)
        blood_sugars = [build_blood_sugar_payload(FactoryBot.build(:blood_sugar, facility: facility))]
        facility.discard

        post(:sync_from_user, params: {blood_sugars: blood_sugars}, as: :json)

        expect(BloodSugar.count).to eq 0
        expect(Encounter.count).to eq 0
        expect(response).to have_http_status(200)
        expect(JSON(response.body)["errors"]).not_to be_empty
      end
    end
  end

  describe "GET sync: send data from server to device;" do
    it_behaves_like "a working V3 sync controller sending records"
    it_behaves_like "a working sync controller that supports region level sync"

    describe "patient prioritisation" do
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

        record_ids = response_1_body["blood_sugars"].map { |r| r["id"] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:facility).to_set).to eq Set[request_facility]

        reset_controller

        # GET request 2
        get :sync_to_user, params: {limit: 4, process_token: response_1_body["process_token"]}
        response_2_body = JSON(response.body)

        record_ids = response_2_body["blood_sugars"].map { |r| r["id"] }
        records = model.where(id: record_ids)
        expect(records.count).to eq 4
        expect(records.map(&:facility).to_set).to eq Set[request_facility, request_2_facility]
      end
    end

    context "hba1c blood sugars" do
      let(:facility) { create(:facility, facility_group: request_facility_group) }

      before :each do
        set_authentication_headers
        create_record_list(2, facility: facility, blood_sugar_type: :random)
        create_record_list(2, facility: facility, blood_sugar_type: :fasting)
        create_record_list(2, facility: facility, blood_sugar_type: :post_prandial)
        create_record_list(2, facility: facility, blood_sugar_type: :hba1c)
      end

      it "sends hba1c blood sugars" do
        get :sync_to_user, params: {limit: 8}

        response_blood_sugars = JSON(response.body)["blood_sugars"]
        response_types = response_blood_sugars.map { |blood_sugar| blood_sugar["blood_sugar_type"] }.to_set

        expect(response_blood_sugars.count).to eq 8
        expect(response_types.count).to eq 4
        expect(response_types).to include("hba1c")
      end
    end

    context "V4 blood_sugar_values" do
      let(:facility) { create(:facility, facility_group: request_facility_group) }

      before :each do
        set_authentication_headers
        create_record(facility: facility, blood_sugar_type: :random)
        create_record(facility: facility, blood_sugar_type: :fasting)
        create_record(facility: facility, blood_sugar_type: :post_prandial)
        create_record(facility: facility, blood_sugar_type: :hba1c)
      end

      it "sends float blood_sugar_values" do
        get :sync_to_user, params: {limit: 4}

        response_blood_sugars = JSON(response.body)["blood_sugars"]
        response_values = response_blood_sugars.map { |blood_sugar| blood_sugar["blood_sugar_value"] }

        response_values.each { |value| expect(value).to be_instance_of(Float) }
      end
    end
  end
end
