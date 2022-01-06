# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Filter parameter logging spec", type: :request do
  let(:request_user) { FactoryBot.create(:user) }
  let(:sync_route) { "/api/v3/patients/sync" }
  let(:build_payload) { -> { build_patient_payload(FactoryBot.build(:patient, age: 9999, registration_facility: request_user.facility)) } }

  let(:auth_headers) do
    {"HTTP_X_USER_ID" => request_user.id,
     "HTTP_X_FACILITY_ID" => request_user.facility.id,
     "HTTP_AUTHORIZATION" => "Bearer #{request_user.access_token}"}
  end
  let(:headers) do
    {"ACCEPT" => "application/json", "CONTENT_TYPE" => "application/json"}.merge(auth_headers)
  end

  it "does not log sensitive patient data" do
    stringio = StringIO.new
    test_logger = Logger.new(stringio)
    allow(ActionController::Base).to receive(:logger).and_return(test_logger)
    allow(Lograge).to receive(:logger).and_return(test_logger)

    patient_payloads = 3.times.map { build_payload.call }
    post sync_route, params: {patients: patient_payloads}.to_json, headers: headers
    get sync_route, params: {}, headers: headers

    patients = patient_payloads.map { |payload| Patient.find(payload[:id]) }
    output = stringio.string
    patients.each do |patient|
      expect(output).to_not match(/\b#{patient.full_name}\b/)
      expect(output).to_not match(/\b#{patient.date_of_birth}\b/) if patient.date_of_birth
      expect(output).to_not match(/\b#{patient.age}\b/)
      if patient.address
        expect(output).to_not match(/\b#{patient.address.street_address}\b/)
        expect(output).to_not match(/\b#{patient.address.village_or_colony}\b/)
        expect(output).to_not match(/\b#{patient.address.district}\b/)
        expect(output).to_not match(/\b#{patient.address.state}\b/)
      end
      patient.phone_numbers.each do |phone_number|
        expect(output).to_not match(/\b#{phone_number}\b/)
      end
    end
  end

  it "only logs allowed parameters and filters out everything else" do
    stringio = StringIO.new
    test_logger = Logger.new(stringio)
    allow(ActionController::Base).to receive(:logger).and_return(test_logger)
    allow(Lograge).to receive(:logger).and_return(test_logger)

    time = Time.parse("January 1 2020 12:00 UTC")
    Timecop.freeze(time) do
      patient_payloads = (1..3).map { build_payload.call }
      post sync_route, params: {patients: patient_payloads}.to_json, headers: headers
      get sync_route, params: {}, headers: headers

      patient_payloads.each do |payload|
        check_payload(stringio.string, payload)
      end
    end
  end

  def check_payload(output, payload)
    payload.each do |attr, value|
      next if value.blank?

      regex = nil
      case value
      when Hash
        check_payload(output, value)
        next
      when Array
        value.each { |v| check_payload(output, v) }
        next
      when ActiveSupport::TimeWithZone
        # We have to search for a substring of the timestamp, because the log can contain a more precise
        # timestamp than the parameters. So we strip off the Timezone info and search for that.
        regex = /\b#{value.iso8601[0..-2]}/
      else
        regex = /\b#{value}\b/
      end

      if ParameterFiltering::ALLOWED_REGEX.match(attr)
        expect(output).to match(regex), "#{output}\n\nLog output should include #{value.inspect} for attribute #{attr}"
      else
        expect(output).to_not match(regex), "#{output}\n\nLog output should not include #{value.inspect} for attribute #{attr}"
      end
    end
  end
end
