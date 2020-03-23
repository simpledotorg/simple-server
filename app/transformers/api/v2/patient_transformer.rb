class Api::V2::PatientTransformer < Api::V3::PatientTransformer
  class << self
    def to_nested_response(patient)
      transformed_patient = super(patient)
                              .except('business_identifiers')
                              .except('recorded_at')
                              .except('reminder_consent')
      transformed_address = transformed_patient['address'].except('zone') if transformed_patient['address'].present?
      transformed_patient.merge('address' => transformed_address)
    end

    def from_nested_request(patient_attributes)
      transformed_attributes = super(patient_attributes)
                                 .except('business_identifiers')
                                 .merge(reminder_consent: reminder_consent(patient_attributes))

      address_attributes = transformed_attributes['address']
                             .except('zone') if transformed_attributes['address'].present?
      transformed_attributes.merge('address' => address_attributes)
    end
  end
end
