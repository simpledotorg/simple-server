class Api::V2::Models < Api::Current::Models
  class << self
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
        .tap { |d| d[:properties].delete(:appointment_type).delete(:recorded_at) }
        .tap { |d| d[:required] -= %w(appointment_type recorded_at) }
    end

    def patient
      super
        .tap { |d| d[:properties].delete(:recorded_at) }
        .tap { |d| d[:required] -= %w(recorded_at) }
    end

    def address
      super
        .tap { |d| d[:properties].delete(:recorded_at) }
        .tap { |d| d[:required] -= %w(recorded_at) }
    end

    def phone_number
      super
        .tap { |d| d[:properties].delete(:recorded_at) }
        .tap { |d| d[:required] -= %w(recorded_at) }
    end

    def blood_pressure
      super
        .tap { |d| d[:properties].delete(:recorded_at) }
        .tap { |d| d[:required] -= %w(recorded_at) }
    end

    def prescription_drug
      super
        .tap { |d| d[:properties].delete(:recorded_at) }
        .tap { |d| d[:required] -= %w(recorded_at) }
    end

    def communication
      super
        .tap { |d| d[:properties].delete(:recorded_at) }
        .tap { |d| d[:required] -= %w(recorded_at) }
    end

    def medical_history
      super
        .tap { |d| d[:properties].delete(:recorded_at) }
        .tap { |d| d[:required] -= %w(recorded_at) }
    end

    def definitions
      super.except(
        :patient_business_identifier,
        :patient_business_identifiers,
      )
    end
  end
end
