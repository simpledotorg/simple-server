require 'rails_helper'

RSpec.describe Api::Current::PrescriptionDrugsController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }
  let(:model) { PrescriptionDrug }

  let(:build_payload) { lambda { build_prescription_drug_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_prescription_drug_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { lambda { |prescription_drug| updated_prescription_drug_payload prescription_drug } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  it_behaves_like 'a sync controller that authenticates user requests'
  it_behaves_like 'a sync controller that audits the data access'
  it_behaves_like 'a working sync controller that short circuits disabled apis'

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'
    it_behaves_like 'a working sync controller updating records'

    describe 'creates new prescription drugs' do
      it 'creates new prescription drugs with associated patient, and facility' do
        request.env['HTTP_X_USER_ID']          = request_user.id
        request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
        
        patient            = FactoryBot.create(:patient)
        facility           = FactoryBot.create(:facility)
        prescription_drugs = (1..10).map do
          build_prescription_drug_payload(FactoryBot.build(:prescription_drug,
                                                           patient:  patient,
                                                           facility: facility))
        end
        post(:sync_from_user, params: { prescription_drugs: prescription_drugs }, as: :json)
        expect(PrescriptionDrug.count).to eq 10
        expect(patient.prescription_drugs.count).to eq 10
        expect(facility.prescription_drugs.count).to eq 10
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working sync controller sending records'
  end
end
