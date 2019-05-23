class Api::Current::PatientTransformer
  class << self
    def recorded_at(patient_params)
      return patient_params['recorded_at'] if patient_params['recorded_at'].present?

      patient_created_at = patient_params['created_at']
      earliest_blood_pressure = BloodPressure
                                  .where(patient_id: patient_params['id'])
                                  .order(recorded_at: :asc)
                                  .first

      earliest_blood_pressure.blank? ?
        patient_created_at : [patient_created_at, earliest_blood_pressure.recorded_at].min
    end

    def from_nested_request(payload_attributes)
      payload_attributes = payload_attributes.to_hash.with_indifferent_access
      address = payload_attributes[:address]
      phone_numbers = payload_attributes[:phone_numbers]
      business_identifiers = payload_attributes[:business_identifiers]
      address_attributes = Api::Current::Transformer.from_request(address) if address.present?

      phone_numbers_attributes = phone_numbers.map do |phone_number|
        Api::Current::Transformer.from_request(phone_number)
      end if phone_numbers.present?

      business_identifiers_attributes = business_identifiers.map do |business_identifier|
        Api::Current::PatientBusinessIdentifierTransformer.from_request(business_identifier)
      end if business_identifiers.present?

      patient_attributes = Api::Current::Transformer.from_request(payload_attributes)
      patient_attributes.merge(
        address: address_attributes,
        phone_numbers: phone_numbers_attributes,
        business_identifiers: business_identifiers_attributes,
        recorded_at: recorded_at(payload_attributes)
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
            Api::Current::PatientBusinessIdentifierTransformer.to_response(business_identifier)
          end
        )
    end
  end
end
