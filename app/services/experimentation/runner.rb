module Experimentation
  class Runner
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

      experiment = Experiment.current_patients.upcoming.find_by(name: name)
      if experiment.nil?
        logger.info("Experiment #{name} not found and may need to be removed from scheduler - exiting.")
        return
      end

      if experiment.end_time < Date.current
        logger.info("Experiment #{name} is past its end_time of #{experiment.end_time} - completing.")
        return
      end

      if experiment.running?
        logger.info("Experiment #{name} is a running current_patient experiment, nothing to do - exiting.")
        return
      end

      eligible_ids = current_patient_candidates(experiment.start_time, experiment.end_time).shuffle!
      logger.info("Found #{eligible_ids.count} eligible patient ids for #{name} experiment, about to schedule_notifications.")

      experiment_patient_count = (0.01 * percentage_of_patients * eligible_ids.length).round
      eligible_ids = eligible_ids.pop(experiment_patient_count)

      while eligible_ids.any?
        batch = eligible_ids.pop(BATCH_SIZE)
        patients = Patient
          .where(id: batch)
          .includes(:appointments)
          .where(appointments: {scheduled_date: experiment.start_time..experiment.end_time, status: "scheduled"})

        patients.each do |patient|
          group = experiment.random_treatment_group
          patient.appointments.each do |appointment|
            schedule_notifications(patient, appointment, group, appointment.scheduled_date)
          end
          group.patients << patient
        end
      end

      logger.info("Finished scheduling notifications for #{name} current experiment - marking as running and exiting.")
    end

    def self.schedule_daily_stale_patient_notifications(name:, patients_per_day: PATIENTS_PER_DAY)
      unless Flipper.enabled?(:experiment)
        logger.info("Experiment feature flag is off. No patients will be added to experiment #{name}.")
        return
      end

      experiment = Experiment.stale_patients.upcoming.find_by(name: name)
      if experiment.nil?
        logger.info("Experiment #{name} not found and may need to be removed from scheduler - exiting.")
        return
      end

      today = Date.current
      if experiment.start_time > today
        logger.info "Experiment #{name} start_time #{experiment.start_time} is in the future, skipping"
        return
      end
      if experiment.end_time < today
        logger.info "Experiment #{name} end_time #{experiment.end_time} has passed, marking complete"
        return
      end

      eligible_ids = StalePatientSelection.call(start_time: today)
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
    end

    def self.abort_experiment(name)
      experiment = Experiment.find_by!(name: name)
      logger.warn "Aborting experiment #{name}! About to cancel all pending or scheduled notifications."

      notifications = experiment.notifications.where(status: ["pending", "scheduled"])
      notifications.find_each do |notification|
        notification.status_cancelled!
      end

      experiment.discard
      logger.warn "Aborting experiment #{name} finished."
    end

    def self.current_patient_candidates(start_time, end_time)
      Experiment.candidate_patients
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
