# frozen_string_literal: true

require "rails_helper"

describe Api::V4::TeleconsultationPayloadValidator, type: :model do
  let!(:facility) { create(:facility) }
  let!(:authorized_user) { create(:user, registration_facility: facility, teleconsultation_facilities: [create(:facility)]) }
  let!(:unauthorized_user) { create(:user, registration_facility: facility) }
  let!(:teleconsultation) { create(:teleconsultation) }

  def new_teleconsultation_payload(attrs = {})
    payload = Api::V4::TeleconsultationPayloadValidator.new(
      build_teleconsultation_payload(teleconsultation).deep_merge(attrs)
    )
    payload.validate
    payload
  end

  it "validates that the request user can teleconsult when record is present" do
    valid_payload = new_teleconsultation_payload("request_user_id" => authorized_user.id)
    invalid_payload = new_teleconsultation_payload("request_user_id" => unauthorized_user.id)

    expect(valid_payload.valid?).to be true
    expect(invalid_payload.valid?).to be false
  end
end
