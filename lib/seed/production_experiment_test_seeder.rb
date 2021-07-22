module Seed
  class ProductionExperimentTestSeeder
    TEMPORARY_PHONE_NUMBER = "8675309"

    def self.call(user_id:, days_till_appointment: 1)
      ExperimentSeeder.call(experiment_name: "production test", experiment_type: "current_patients")

      now = Time.current
      today = Date.current
      user = User.find(user_id)
      facility = user.registration_facility

      ["Hari AB Tester", "Vikram AB Tester", "Srihari AB Tester", "Pragati AB Tester", "Prabhanshu AB Tester"].each do |name|
          patient = Patient.create!(id: SecureRandom.uuid, full_name: name, status: "active", device_created_at: now,
                                    device_updated_at: now, registration_user: user, registration_facility: facility,
                                    assigned_facility: facility)
          patient.phone_numbers.create!(id: SecureRandom.uuid, number: TEMPORARY_PHONE_NUMBER, phone_type: "mobile",
                                        active: true, device_created_at: now, device_updated_at: now)
          Appointment.create!(scheduled_date: today + days_till_appointment, patient: patient, facility: facility,
                              device_created_at: now, device_updated_at: now, appointment_type: "manual")
      end
    end
  end
end
