class Api::Current::PatientTransformer
  class << self
    def from_nested_request(payload_attributes)
      payload_attributes = payload_attributes.to_hash.with_indifferent_access
      address = payload_attributes[:address]
      phone_numbers = payload_attributes[:phone_numbers]
      address_attributes = Api::Current::Transformer.from_request(address) if address.present?
      phone_numbers_attributes = phone_numbers.map { |phone_number| Api::Current::Transformer.from_request(phone_number) } if phone_numbers.present?
      patient_attributes = Api::Current::Transformer.from_request(payload_attributes)
      patient_attributes.merge(
        address: address_attributes,
        phone_numbers: phone_numbers_attributes
      ).with_indifferent_access
    end

    def to_nested_response(patient)
      Api::Current::Transformer.to_response(patient)
        .except('address_id')
        .except('test_data')
        .merge(
          'address' => Api::Current::Transformer.to_response(patient.address),
          'phone_numbers' => patient.phone_numbers.map { |phone_number| Api::Current::Transformer.to_response(phone_number).except('patient_id') }
        ).as_json
    end
  end
end