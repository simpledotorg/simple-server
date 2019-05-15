class Api::V2::Models < Api::Current::Models
  class << self
    def patient
      super
        .tap { |d| d[:properties].delete(:recorded_at) }
        .tap { |d| d[:required] -= %w(recorded_at) }
    end

    def blood_pressure
      super
        .tap { |d| d[:properties].delete(:recorded_at) }
        .tap { |d| d[:required] -= %w(recorded_at) }
    end

    def nested_patient
      patient.deep_merge(
        properties: {
          address: { '$ref' => '#/definitions/address' },
          phone_numbers: { '$ref' => '#/definitions/phone_numbers' } },
        description: 'Patient with address and phone numbers nested.',
      )
    end

    def appointment
      super
        .tap { |d| d[:properties].delete(:appointment_type) }
        .tap { |d| d[:required] -= %w(appointment_type) }
    end

    def definitions
      super.except(
        :patient_business_identifier,
        :patient_business_identifiers,
      )
    end

    def communication
      super.tap do |d|
        d[:properties][:communication_result][:enum] -= %i(unsuccessful unknown in_progress)
      end.tap do |d|
        d[:properties][:communication_type][:enum] -= %w(missed_visit_sms_reminder)
      end
    end
  end
end
