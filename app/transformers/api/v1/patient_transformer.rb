class Api::V1::PatientTransformer < Api::Current::PatientTransformer
  class << self
    def to_nested_response(patient)
      super(patient).except('business_identifiers')
    end
  end
end