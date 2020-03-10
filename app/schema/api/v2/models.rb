class Api::V2::Models < Api::V3::Models
  class << self
    def patient
      super
        .tap do |d|
        d[:properties]
          .delete(:recorded_at)
          .delete(:reminder_consent)
      end
    end

    def blood_pressure
      super
        .tap { |d| d[:properties].delete(:recorded_at) }
    end

    def address
      super.tap { |d| d[:properties].delete(:zone) }
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
        .tap { |d| d[:properties].delete(:creation_facility_id) }
        .tap { |d| d[:required] -= %w(appointment_type) }
    end

    def medical_history
      super.tap { |d| d[:properties].delete(:hypertension) }
    end

    def definitions
      super.except(
        :patient_business_identifier,
        :patient_business_identifiers,
        :blood_sugar,
        :blood_sugars
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
