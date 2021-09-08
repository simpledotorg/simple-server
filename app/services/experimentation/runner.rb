module Experimentation
  class Runner
    LAST_EXPERIMENT_BUFFER = 14.days.freeze
    PATIENTS_PER_DAY = 10_000
    BATCH_SIZE = 100

    def self.logger
      @logger ||= Notification.logger(class: name)
    end

    def self.start_current_patient_experiment(name:, percentage_of_patients: 100)
      unless Flipper.enabled?(:experiment)
        logger.info("Experiment feature flag is off. Experiment #{name} will not be started.")
        return
      end

      experiment = Experiment.current_patients.find_by(name: name, state: [:new, :running])
      if experiment.nil?
        logger.info("Experiment #{name} not found and may need to be removed from scheduler - exiting.")
        return
      end

      if experiment.end_date < Date.current
        logger.info("Experiment #{name} is past its end_date of #{experiment.end_date} - completing.")
        experiment.complete_state!
        return
      end

      if experiment.running_state?
        logger.info("Experiment #{name} is a running current_patient experiment, nothing to do - exiting.")
        return
      end

      logger.info("Experiment #{name} is starting selecting state.")
      experiment.selecting_state!

      eligible_ids = current_patient_candidates(experiment.start_date, experiment.end_date).shuffle!
      logger.info("Found #{eligible_ids.count} eligible patient ids for #{name} experiment, about to schedule_notifications.")

      experiment_patient_count = (0.01 * percentage_of_patients * eligible_ids.length).round
      eligible_ids = eligible_ids.pop(experiment_patient_count)

      while eligible_ids.any?
        batch = eligible_ids.pop(BATCH_SIZE)
        patients = Patient
          .where(id: batch)
          .includes(:appointments)
          .where(appointments: {scheduled_date: experiment.start_date..experiment.end_date, status: "scheduled"})

        patients.each do |patient|
          group = experiment.random_treatment_group
          patient.appointments.each do |appointment|
            schedule_notifications(patient, appointment, group, appointment.scheduled_date)
          end
          group.patients << patient
        end
      end

      logger.info("Finished scheduling notifications for #{name} current experiment - marking as running and exiting.")
      experiment.running_state!
    end

    def self.extend_current_patient_experiment(name:, end_date:, percentage_of_patients: 100)
      unless Flipper.enabled?(:experiment)
        logger.info("Experiment feature flag is off. Experiment #{name} will not be extended.")
        return
      end

      experiment = Experiment.current_patients.find_by(name: name, state: [:running])
      if experiment.nil?
        logger.info("Experiment #{name} not available for extension. It may not be running, or may need to be removed from scheduler - exiting.")
        return
      end

      if end_date <= experiment.end_date
        logger.info("New end date must be later than existing end date. Experiment #{name} is currently scheduled to end on #{experiment.end_date}.")
        return
      end

      extension_start_date = experiment.end_date + 1.day
      extension_end_date = end_date

      logger.info("Updating Experiment #{name} end date to #{end_date}.")
      experiment.update!(end_date: end_date)

      logger.info("Experiment #{name} is starting selecting state. Selecting patients for extended period #{extension_start_date} to #{extension_end_date}")
      experiment.selecting_state!

      eligible_ids = current_patient_candidates(extension_start_date, extension_end_date).shuffle!
      logger.info("Found #{eligible_ids.count} eligible patient ids for #{name} experiment, about to schedule_notifications.")

      experiment_patient_count = (0.01 * percentage_of_patients * eligible_ids.length).round
      eligible_ids = eligible_ids.pop(experiment_patient_count)

      while eligible_ids.any?
        batch = eligible_ids.pop(BATCH_SIZE)
        patients = Patient
          .where(id: batch)
          .includes(:appointments)
          .where(appointments: {scheduled_date: extension_start_date..extension_end_date, status: "scheduled"})

        patients.each do |patient|
          group = experiment.random_treatment_group
          patient.appointments.each do |appointment|
            schedule_notifications(patient, appointment, group, appointment.scheduled_date)
          end
          group.patients << patient
        end
      end

      logger.info("Finished scheduling notifications for #{name} current experiment - marking as running and exiting.")
      experiment.running_state!
    end

    def self.schedule_daily_stale_patient_notifications(name:, patients_per_day: PATIENTS_PER_DAY)
      unless Flipper.enabled?(:experiment)
        logger.info("Experiment feature flag is off. No patients will be added to experiment #{name}.")
        return
      end

      experiment = Experiment.find_by(name: name, experiment_type: "stale_patients", state: [:new, :running])
      if experiment.nil?
        logger.info("Experiment #{name} not found and may need to be removed from scheduler - exiting.")
        return
      end

      today = Date.current
      if experiment.start_date > today
        logger.info "Experiment #{name} start_date #{experiment.start_date} is in the future, skipping"
        return
      end
      if experiment.end_date < today
        logger.info "Experiment #{name} end_date #{experiment.end_date} has passed, marking complete"
        experiment.complete_state!
        return
      end
      experiment.selecting_state!

      eligible_ids = StalePatientSelection.call(start_date: today)
      logger.info "Experiment #{name} found #{eligible_ids.count} eligible patient ids for stale patient reminders"
      if eligible_ids.any?
        eligible_ids.shuffle!
        daily_ids = eligible_ids.pop(patients_per_day)
        daily_patients = Patient.where(id: daily_ids).includes(:appointments)
        daily_patients.each do |patient|
          group = experiment.random_treatment_group
          schedule_notifications(patient, patient.appointments.last, group, today)
          group.patients << patient
        end
      end

      logger.info("Finished scheduling notifications for #{name} stale experiment - marking as running and exiting.")
      experiment.running_state!
    end

    def self.abort_experiment(name)
      experiment = Experiment.find_by!(name: name)
      logger.warn "Aborting experiment #{name}! About to cancel all pending or scheduled notifications."
      experiment.cancelled_state!

      notifications = experiment.notifications.where(status: ["pending", "scheduled"])
      notifications.find_each do |notification|
        notification.status_cancelled!
      end
      logger.warn "Aborting experiment #{name} finished."
    end

    def self.current_patient_candidates(start_date, end_date)
      Experiment.candidate_patients
        .joins(:appointments)
        .merge(Appointment.status_scheduled)
        .where("appointments.scheduled_date BETWEEN ? and ?", start_date, end_date)
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
