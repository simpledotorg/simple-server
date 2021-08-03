# require_relative "stale_patient_selection"

module Experimentation
  class Runner
    LAST_EXPERIMENT_BUFFER = 14.days.freeze
    PATIENTS_PER_DAY = 10_000
    BATCH_SIZE = 100

    def self.logger
      @logger ||= Experimentation.logger(class: name)
    end

    def self.start_current_patient_experiment(name:, percentage_of_patients: 100)
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

      logger.info("Finished scheduling notifications for #{name} experiment - marking as running and exiting.")
      experiment.running_state!
    end

    def self.schedule_daily_stale_patient_notifications(name:, patients_per_day: PATIENTS_PER_DAY)
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
      logger.info experiment: name, msg: "Found #{eligible_ids.count} eligible patient ids for stale patient reminders"
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

      experiment.running_state!
    end

    def self.abort_experiment(name)
      experiment = Experiment.find_by!(name: name)
      experiment.cancelled_state!

      notifications = experiment.notifications.where(status: ["pending", "scheduled"])
      notifications.find_each do |notification|
        notification.status_cancelled!
      end
    end

    protected

    def self.random_treatment_group(experiment)
      group = experiment.random_treatment_group
      logger.info "adding patient to group #{group.inspect}"
      group
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
