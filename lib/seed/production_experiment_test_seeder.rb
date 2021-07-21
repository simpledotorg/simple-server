module Seed
  class ProductionExperimentTestSeeder
    include ActiveSupport::Benchmarkable

    def self.call(days_till_start: 1, user_id:)
      new.call(days_till_start: days_till_start, user_id: user_id)
    end

    def call(days_till_start: 1, user_id:)
      experiment = Experimentation::Experiment.create!(name: "production test", experiment_type: "current_patients", state: "new")
      control_group = experiment.treatment_groups.create!(description: "control")
      treatment_group = experiment.treatment_groups.create!(description: "professional_request")
      treatment_group.reminder_templates.create!(message: "notifications.set01.professional_request", remind_on_in_days: -1)
      treatment_group.reminder_templates.create!(message: "notifications.set02.professional_request", remind_on_in_days: 0)
      treatment_group.reminder_templates.create!(message: "notifications.set03.professional_request", remind_on_in_days: 1)

      now = Time.current
      today = Date.current
      user = User.find(user_id)
      facility = user.registration_facility

      patient = Patient.create!(id: SecureRandom.uuid, full_name: "Hari AB Tester", status: "active", device_created_at: now, device_updated_at: now, registration_user: user)
      patient.phone_numbers.create!(id: SecureRandom.uuid, number: "this should not be in a public git", phone_type: "mobile", active: true, device_created_at: now, device_updated_at: now)
      Appointment.create!(scheduled_date: today + days_till_start, patient: patient, facility: facility, device_created_at: now, device_updated_at: now, appointment_type: "manual")
      patient = Patient.create!(id: SecureRandom.uuid, full_name: "Vikram AB Tester", status: "active", device_created_at: now, device_updated_at: now, registration_user: user)
      patient.phone_numbers.create!(id: SecureRandom.uuid, number: "this should not be in a public git", phone_type: "mobile", active: true, device_created_at: now, device_updated_at: now)
      Appointment.create!(scheduled_date: today + days_till_start, patient: patient, facility: facility, device_created_at: now, device_updated_at: now, appointment_type: "manual")
      patient = Patient.create!(id: SecureRandom.uuid, full_name: "Srihari AB Tester", status: "active", device_created_at: now, device_updated_at: now, registration_user: user)
      patient.phone_numbers.create!(id: SecureRandom.uuid, number: "this should not be in a public git", phone_type: "mobile", active: true, device_created_at: now, device_updated_at: now)
      Appointment.create!(scheduled_date: today + days_till_start, patient: patient, facility: facility, device_created_at: now, device_updated_at: now, appointment_type: "manual")
      patient = Patient.create!(id: SecureRandom.uuid, full_name: "Pragati AB Tester", status: "active", device_created_at: now, device_updated_at: now, registration_user: user)
      patient.phone_numbers.create!(id: SecureRandom.uuid, number: "this should not be in a public git", phone_type: "mobile", active: true, device_created_at: now, device_updated_at: now)
      Appointment.create!(scheduled_date: today + days_till_start, patient: patient, facility: facility, device_created_at: now, device_updated_at: now, appointment_type: "manual")

      # ExperimentControlService.start_current_patient_experiment(experiment.name, 1, 5)
    end
  end
end
