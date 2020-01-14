require 'rails_helper'

RSpec.describe Api::V2::AppointmentTransformer do
  describe 'to_response' do
    let(:appointment) { FactoryBot.build(:appointment) }

    it 'removes appointment_type and user_id from appointment hashes' do
      transformed_appointment = Api::V2::AppointmentTransformer.to_response(appointment)
      expect(transformed_appointment).not_to include('appointment_type', 'user_id')
    end
  end

  describe 'from_request' do
    let(:appointment_payload) { build_appointment_payload }

    it 'removes appointment_type from appointment hashes' do
      transformed_payload = Api::V2::AppointmentTransformer.from_request(appointment_payload)
      expect(transformed_payload).not_to include('appointment_type')
    end
  end
end
