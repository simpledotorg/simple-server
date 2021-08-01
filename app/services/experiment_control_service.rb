class ExperimentControlService
  LAST_EXPERIMENT_BUFFER = 14.days.freeze
  PATIENTS_PER_DAY = 10_000
  BATCH_SIZE = 100

  class << self
    def start_current_patient_experiment(name:, percentage_of_patients: 100)
      experiment = Experimentation::Experiment.find_by(name: name, experiment_type: "current_patients", state: [:new, :running])
      unless experiment
        Sentry.capture_message("Experiment #{name} not found and may need to be removed from scheduler.")
        return
      end

      if experiment.end_date < Date.current
        experiment.complete_state!
        return
      end

      return if experiment.state == "running"

      experiment.update!(state: "selecting")

      eligible_ids = current_patient_candidates(experiment.start_date, experiment.end_date).shuffle!

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

      experiment.running_state!
    end

    def schedule_daily_stale_patient_notifications(name:, patients_per_day: PATIENTS_PER_DAY)
      experiment = Experimentation::Experiment.find_by(name: name, experiment_type: "stale_patients", state: [:new, :running])
      unless experiment
        Sentry.capture_message("Experiment #{name} not found and may need to be removed from scheduler.")
        return
      end

      today = Date.current
      return if experiment.start_date > today
      if experiment.end_date < today
        experiment.complete_state!
        return
      end
      experiment.selecting_state!

      eligible_ids = Experimentation::StalePatientSelection.call(start_date: today)
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

    def abort_experiment(name)
      experiment = Experimentation::Experiment.find_by!(name: name)
      experiment.cancelled_state!

      notifications = experiment.notifications.where(status: ["pending", "scheduled"])
      notifications.find_each do |notification|
        notification.status_cancelled!
      end
    end

    protected

    def current_patient_candidates(start_date, end_date)
      Experimentation::Experiment.candidate_patients
        .joins(:appointments)
        .merge(Appointment.status_scheduled)
        .where("appointments.scheduled_date BETWEEN ? and ?", start_date, end_date)
        .distinct
        .pluck(:id)
    end

    def schedule_notifications(patient, appointment, group, schedule_date)
      group.reminder_templates.each do |template|
        remind_on = schedule_date + template.remind_on_in_days.days
        Notification.create!(
          remind_on: remind_on,
          status: "pending",
          message: template.message,
          experiment: group.experiment,
          reminder_template: template,
          subject: appointment,
          patient: patient,
          purpose: :experimental_appointment_reminder
        )
      end
    end
  end
end
