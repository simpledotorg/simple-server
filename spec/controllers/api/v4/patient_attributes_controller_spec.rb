require 'rails_helper'

describe Api::V4::PatientAttributesController, type: :controller do

  let(:request_user) { create(:user) }
  let(:model) { PatientAttribute }
  let(:build_payload) { -> { build_patient_attribute_payload } }
  let(:build_invalid_payload) { -> { build_invalid_patient_attribute_payload } }

  def create_facility
    create(:facility, facility_group: request_user.facility.facility_group)
  end
  alias_method :with_facility, :create_facility

  def build_patient(facility)
    build(:patient, registration_facility: facility)
  end

  def create_record(options = {})
    patient = build_patient with_facility
    create(:patient_attribute, options.merge(patient: patient))
  end

  def create_record_list(n, options = {})
    patient = build_patient with_facility
    create_list(:patient_attribute, n, options.merge(patient: patient))
  end

  # it_behaves_like "a sync controller that authenticates user requests"
  it_behaves_like "a sync controller that audits the data access"

  describe "POST sync: send data from device to server;" do
    # it_behaves_like "a working sync controller creating records"
    # it_behaves_like "a working sync controller updating records"
  end
end
