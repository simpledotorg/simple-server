class ExperimentControlService
  LAST_EXPERIMENT_BUFFER = 14.days.freeze
  PATIENTS_PER_DAY = 10_000
  BATCH_SIZE = 100

  class << self
    def start_current_patient_experiment(name, days_til_start, days_til_end, percentage_of_patients = 100)
      experiment = Experimentation::Experiment.find_by!(name: name, experiment_type: "current_patients")
      experiment_start = days_til_start.days.from_now.beginning_of_day
      experiment_end = days_til_end.days.from_now.end_of_day

      experiment.update!(state: "selecting", start_date: experiment_start.to_date, end_date: experiment_end.to_date)

      eligible_ids = Experimentation::Experiment.candidate_patients
        .joins(:appointments)
        .merge(Appointment.status_scheduled)
        .where("appointments.scheduled_date BETWEEN ? and ?", experiment_start, experiment_end)
        .distinct
        .pluck(:id)
      eligible_ids.shuffle!

      experiment_patient_count = (0.01 * percentage_of_patients * eligible_ids.length).round
      eligible_ids = eligible_ids.pop(experiment_patient_count)

      while eligible_ids.any?
        batch = eligible_ids.pop(BATCH_SIZE)
        patients = Patient
          .where(id: batch)
          .includes(:appointments)
          .where(appointments: {scheduled_date: experiment_start..experiment_end})

        patients.each do |patient|
          group = experiment.group_for(patient.id)
          patient.appointments.each do |appointment|
            schedule_reminders(patient, appointment, group, appointment.scheduled_date)
          end
          group.patients << patient
        end
      end

      experiment.update!(state: "running")
    end

    def start_stale_patient_experiment(name, days_til_start, days_til_end, patients_per_day: PATIENTS_PER_DAY)
      experiment = Experimentation::Experiment.find_by!(name: name, experiment_type: "stale_patients")
      total_days = days_til_end - days_til_start + 1
      start_date = days_til_start.days.from_now.to_date

      experiment.update!(state: "selecting", start_date: start_date, end_date: days_til_end.days.from_now.to_date)

      eligible_ids = Experimentation::StalePatientSelection.call(start_date: start_date)
      eligible_ids.shuffle!

      schedule_date = start_date
      total_days.times do
        daily_ids = eligible_ids.pop(patients_per_day)
        break if daily_ids.empty?
        daily_patients = Patient.where(id: daily_ids).includes(:appointments)
        daily_patients.each do |patient|
          group = experiment.group_for(patient.id)
          schedule_reminders(patient, patient.appointments.last, group, schedule_date)
          group.patients << patient
        end
        schedule_date += 1.day
      end

      experiment.update!(state: "running")
    end

    protected

    def schedule_reminders(patient, appointment, group, schedule_date)
      group.reminder_templates.each do |template|
        remind_on = schedule_date + template.remind_on_in_days.days
        AppointmentReminder.create!(
          remind_on: remind_on,
          status: "pending",
          message: template.message,
          experiment: group.experiment,
          reminder_template: template,
          appointment: appointment,
          patient: patient
        )
      end
    end
  end
end
