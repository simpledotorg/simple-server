# This is not a scientific experiment like active and stale patient experiments. It does not need or have human study
# approval and we are not excluding patients under 18 years old. We are leveraging the experimentation framework to
# request patients to visit clinics to pick up enough blood pressure medication to last the current covid spike.
# We're using the experimentation framework for two reasons:
# 1) we want most of the same functionality, including batched daily notification scheduling and the ability to track
#    results by leveraging the experimentation and notification models
# 2) this is an excellent opportunity to real-world test the experimentation framework
module Experimentation
  class MedicationReminderService
    PATIENTS_PER_DAY = 10_000

    class << self
      def schedule_daily_notifications(patients_per_day: PATIENTS_PER_DAY)
        return unless Flipper.enabled?(:experiment)

        experiment = Experimentation::Experiment.upcoming.find_by!(experiment_type: "medication_reminder")

        eligible_ids = medication_reminder_patients(experiment)
        if eligible_ids.any?
          eligible_ids.shuffle!

          daily_ids = eligible_ids.pop(patients_per_day)
          daily_patients = Patient.where(id: daily_ids)
          daily_patients.each do |patient|
            group = experiment.random_treatment_group
            schedule_notifications(patient, group)
            group.patients << patient
          end
        end
      end

      protected

      def schedule_notifications(patient, group)
        group.reminder_templates.each do |template|
          remind_on = Date.current + template.remind_on_in_days.days
          Notification.create!(
            remind_on: remind_on,
            status: "pending",
            message: template.message,
            experiment: group.experiment,
            reminder_template: template,
            subject: nil,
            patient: patient,
            purpose: :covid_medication_reminder
          )
        end
      end

      def medication_reminder_patients(experiment)
        Patient
          .with_hypertension
          .contactable
          .includes(treatment_group_memberships: [treatment_group: [:experiment]])
          .where("experiments.id IS NULL OR experiments.id != ?", experiment.id)
          .references(:experiment)
          .where(
            "NOT EXISTS (SELECT 1 FROM blood_pressures WHERE blood_pressures.patient_id = patients.id AND blood_pressures.device_created_at > ?)",
            30.days.ago.beginning_of_day
          )
          .distinct
          .pluck(:id)
      end
    end
  end
end
