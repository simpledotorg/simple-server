class Api::Current::PatientTransformer
  class << self
    def from_nested_request(payload_attributes)
      payload_attributes = payload_attributes.to_hash.with_indifferent_access
      address = payload_attributes[:address]
      phone_numbers = payload_attributes[:phone_numbers]
      business_identifiers = payload_attributes[:business_identifiers]
      address_attributes = Api::Current::Transformer.from_request(address) if address.present?
      phone_numbers_attributes = phone_numbers.map { |phone_number| Api::Current::Transformer.from_request(phone_number) } if phone_numbers.present?
      if business_identifiers.present?
        business_identifiers_attributes = business_identifiers.map do |business_identifier|
          business_identifier_metadata = JSON.parse(business_identifier[:metadata]) if business_identifier[:metadata].present?
          Api::Current::Transformer.from_request(business_identifier
                                                   .merge(metadata: business_identifier_metadata))
        end
      end
      patient_attributes = Api::Current::Transformer.from_request(payload_attributes)
      patient_attributes.merge(
        address: address_attributes,
        phone_numbers: phone_numbers_attributes,
        business_identifiers: business_identifiers_attributes
      ).with_indifferent_access
    end

    def to_nested_response(patient)
      Api::Current::Transformer.to_response(patient)
        .except('address_id')
        .except('registration_user_id')
        .except('registration_facility_id')
        .except('test_data')
        .merge(
          'address' => Api::Current::Transformer.to_response(patient.address),
          'phone_numbers' => patient.phone_numbers.map do |phone_number|
            Api::Current::Transformer.to_response(phone_number).except('patient_id')
          end,
          'business_identifiers' => patient.business_identifiers.map do |business_identifier|
            Api::Current::Transformer
              .to_response(business_identifier)
              .except('patient_id')
              .merge('metadata' => business_identifier.metadata&.to_json)
          end
        ).as_json
    end
  end
end