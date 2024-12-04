require "rails_helper"

describe Api::V4::CvdRisksController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:model) { CvdRisk }
  let(:build_payload) { -> { build(:cvd_risk).attributes.with_payload_keys } }
  let(:build_invalid_payload) { -> { build(:cvd_risk, :invalid) } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }
  let(:update_payload) { ->(cvd_risk) { cvd_risk.attributes.with_payload_keys.merge(updated_at: 5.days.from_now) } }

  def build_patient
    facility = create(:facility, facility_group_id: request_facility_group.id)
    build(:patient, registration_facility_id: facility.id)
  end

  def create_record(options = {})
    create(:cvd_risk, options.merge(patient: build_patient))
  end

  def create_record_list(n, options = {})
    create_list(:cvd_risk, n, options.merge(patient: build_patient))
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
