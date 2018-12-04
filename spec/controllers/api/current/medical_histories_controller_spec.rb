require 'rails_helper'

RSpec.describe Api::Current::MedicalHistoriesController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }
  let(:request_facility) { FactoryBot.create(:facility) }
  before :each do
    request.env['X_USER_ID'] = request_user.id
    request.env['X_FACILITY_ID'] = request_facility.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  let(:model) { MedicalHistory }

  let(:build_payload) { lambda { build_medical_history_payload_current } }
  let(:build_invalid_payload) { lambda { build_invalid_medical_history_payload_current } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { lambda { |medical_history| updated_medical_history_payload_current medical_history } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  def create_record(options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    patient = FactoryBot.create(:patient, registration_facility: facility)
    FactoryBot.create(:medical_history, options.merge(patient: patient))
  end

  def create_record_list(n, options = {})
    facility = FactoryBot.create(:facility, facility_group_id: request_user.facility.facility_group.id)
    patient = FactoryBot.create(:patient, registration_facility_id: facility.id)
    FactoryBot.create_list(:medical_history, n, options.merge(patient: patient))
  end

  it_behaves_like 'a sync controller that authenticates user requests'
  it_behaves_like 'a sync controller that audits the data access'
  it_behaves_like 'a working sync controller that short circuits disabled apis'

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'
    it_behaves_like 'a working sync controller updating records'
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working Current sync controller sending records'
  end
end
