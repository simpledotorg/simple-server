class Api::V2::PatientTransformer < Api::Current::PatientTransformer
  class << self
    def to_nested_response(patient)
      super(patient)
        .except('business_identifiers')
        .except('recorded_at')
    end

    def from_nested_request(patient_attributes)
      super(patient_attributes)
        .except('business_identifiers')
    end
  end
end
