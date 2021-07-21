class CreateTestExperiment < ActiveRecord::Migration[5.2]
  def up
    if CountryConfig.current_country?("India")
      experiment = Experimentation::Experiment.create!(name: "production test", experiment_type: "current_patients", state: "new")
      control_group = experiment.treatment_groups.create!(description: "control")
      treatment_group = experiment.treatment_groups.create!(description: "professional_request")
      treatment_group.reminder_templates.create!(message: "notifications.set01.professional_request", remind_on_in_days: -1)
      treatment_group.reminder_templates.create!(message: "notifications.set02.professional_request", remind_on_in_days: 0)
      treatment_group.reminder_templates.create!(message: "notifications.set03.professional_request", remind_on_in_days: 1)

      now = Time.current
      user = User.last # we should find a user we can use or create a new one
      patient = Patient.create!(id: SecureRandom.uuid, full_name: "Hari AB Tester", status: "active", device_created_at: now, device_updated_at: now, registration_user: user)
      patient.phone_numbers.create!(id: SecureRandom.uuid, number: "this should not be in a public git", phone_type: "mobile", active: true, device_created_at: now, device_updated_at: now)
      patient = Patient.create!(id: SecureRandom.uuid, full_name: "Vikram AB Tester", status: "active", device_created_at: now, device_updated_at: now, registration_user: user)
      patient.phone_numbers.create!(id: SecureRandom.uuid, number: "this should not be in a public git", phone_type: "mobile", active: true, device_created_at: now, device_updated_at: now)
      patient = Patient.create!(id: SecureRandom.uuid, full_name: "Srihari AB Tester", status: "active", device_created_at: now, device_updated_at: now, registration_user: user)
      patient.phone_numbers.create!(id: SecureRandom.uuid, number: "this should not be in a public git", phone_type: "mobile", active: true, device_created_at: now, device_updated_at: now)
      patient = Patient.create!(id: SecureRandom.uuid, full_name: "Pragati AB Tester", status: "active", device_created_at: now, device_updated_at: now, registration_user: user)
      patient.phone_numbers.create!(id: SecureRandom.uuid, number: "this should not be in a public git", phone_type: "mobile", active: true, device_created_at: now, device_updated_at: now)

      # create appointments during experiment window

      ExperimentControlService.start_current_patient_experiment(experiment.name, 1, 5)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
