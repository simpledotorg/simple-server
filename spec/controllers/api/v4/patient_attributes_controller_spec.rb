require "rails_helper"

describe Api::V4::PatientAttributesController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { PatientAttribute }
  let(:build_payload) { -> { build_patient_attribute_payload } }
  let(:build_invalid_payload) { -> { build_invalid_patient_attribute_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }
  let(:update_payload) { ->(patient_attribute) { updated_patient_attributes_payload(patient_attribute) } }

  def create_record(options = {})
    facility = create(:facility, facility_group: request_facility_group)
    patient = build(:patient, registration_facility: facility)
    create(:patient_attribute, options.merge(patient: patient))
  end

  def create_record_list(n, options = {})
    facility = create(:facility, facility_group_id: request_facility_group.id)
    patient = build(:patient, registration_facility_id: facility.id)
    create_list(:patient_attribute, n, options.merge(patient: patient))
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
        it "no-ops the discarded records" do
          existing_records.map(&:discard)
          post :sync_from_user, params: updated_payload, as: :json

          updated_records.each do |record|
            db_record = model.with_discarded.find(record["id"])

            expect(db_record).to be_discarded

            expected_hash = db_record
              .attributes
              .to_json_and_back
              .except("user_id")
              .with_payload_keys.with_int_timestamps
            actual_hash = record
              .to_json_and_back
              .except("user_id")
              .with_int_timestamps
            expect(expected_hash).not_to eq(actual_hash)
          end
        end

        it "with updated record attributes" do
          post :sync_from_user, params: updated_payload, as: :json

          updated_records.each do |record|
            db_record = model.find(record["id"])
            expected = db_record
              .attributes
              .with_payload_keys
              .with_int_timestamps
              .except("user_id")
              .merge(
                "height" => db_record["height"].to_f,
                "weight" => db_record["weight"].to_f
              )
            actual = record
              .to_json_and_back
              .with_int_timestamps
              .except("user_id")
            expect(expected).to eq(actual)
          end
        end
      end
    end
  end

  describe "GET sync: send data from server to device;" do
    it_behaves_like "a working V3 sync controller sending records"
  end
end
