module Experimentation
  class Runner
    PATIENTS_PER_DAY = 10_000
    BATCH_SIZE = 100

    def self.logger
      @logger ||= Notification.logger(class: name)
    end

    def self.start_current_patient_experiment(name:, percentage_of_patients: 100)
      experiment = Experiment.current_patients.upcoming.find_by(name: name)

      eligible_ids = current_patient_candidates(experiment.start_time, experiment.end_time).shuffle!
      experiment_patient_count = (0.01 * percentage_of_patients * eligible_ids.length).round
      eligible_ids = eligible_ids.pop(experiment_patient_count)

      while eligible_ids.any?
        batch = eligible_ids.pop(BATCH_SIZE)
        patients = Patient
          .where(id: batch)
          .includes(:appointments)
          .where(appointments: {scheduled_date: experiment.start_time.to_date..experiment.end_time.to_date, status: "scheduled"})

        patients.each do |patient|
          group = experiment.random_treatment_group
          patient.appointments.each do |appointment|
            schedule_notifications(patient, appointment, group, appointment.scheduled_date)
          end
          group.enroll(patient)
        end
      end

      logger.info("Finished scheduling notifications for #{name} current experiment - marking as running and exiting.")
    end

    def self.schedule_daily_stale_patient_notifications(name:, patients_per_day: PATIENTS_PER_DAY)
      experiment = Experiment.stale_patients.running.find_by(name: name)

      today = Date.today
      eligible_ids = StalePatientSelection.call(date: today)
      if eligible_ids.any?
        eligible_ids.shuffle!
        daily_ids = eligible_ids.pop(patients_per_day)
        daily_patients = Patient.where(id: daily_ids).includes(:appointments)
        daily_patients.each do |patient|
          group = experiment.random_treatment_group
          schedule_notifications(patient, patient.appointments.last, group, today)
          group.enroll(patient)
        end
      end

      logger.info("Finished scheduling notifications for #{name} stale experiment - marking as running and exiting.")
    end

    def self.current_patient_candidates(start_time, end_time)
      NotificationsExperiment.eligible_patients
        .joins(:appointments)
        .merge(Appointment.status_scheduled)
        .where("appointments.scheduled_date BETWEEN ? and ?", start_time, end_time)
        .distinct
        .pluck(:id)
    end

    def self.schedule_notifications(patient, appointment, group, schedule_date)
      group.reminder_templates.each do |template|
        remind_on = schedule_date + template.remind_on_in_days.days
        Notification.create!(
          experiment: group.experiment,
          message: template.message,
          patient: patient,
          purpose: :experimental_appointment_reminder,
          remind_on: remind_on,
          reminder_template: template,
          status: "pending",
          subject: appointment
        )
      end
    end
  end
end
