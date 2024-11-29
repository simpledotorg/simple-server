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
  let(:update_payload) { ->(patient_attribute) { updated_patient_attribute_payload patient_attribute } }

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
    it_behaves_like "a working sync controller updating records"
  end

  describe "GET sync: send data from server to device;" do
    it_behaves_like "a working V3 sync controller sending records"
  end
end
