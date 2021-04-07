class ExperimentControlService
  LAST_EXPERIMENT_BUFFER = 14.days.freeze
  INACTIVE_PATIENTS_ELIGIBILITY_START = 365.days.freeze
  INACTIVE_PATIENTS_ELIGIBILITY_END = 35.days.freeze
  PATIENTS_PER_DAY = 10_000
  BATCH_SIZE = 100

  class << self
    def start_current_patient_experiment(name, days_til_start, days_til_end, percentage_of_patients = 100)
      experiment = Experimentation::Experiment.find_by!(name: name, experiment_type: "active_patients")
      experiment_start = days_til_start.days.from_now.beginning_of_day
      experiment_end = days_til_end.days.from_now.end_of_day

      experiment.update!(state: "selecting", start_date: experiment_start.to_date, end_date: experiment_end.to_date)

      eligible_ids = patient_pool
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

    def start_inactive_patient_experiment(name, days_til_start, days_til_end)
      experiment = Experimentation::Experiment.find_by!(name: name, experiment_type: "stale_patients")
      total_days = days_til_end - days_til_start + 1
      date = days_til_start.days.from_now.to_date
      eligibility_start = (date - INACTIVE_PATIENTS_ELIGIBILITY_START).beginning_of_day
      eligibility_end = (date - INACTIVE_PATIENTS_ELIGIBILITY_END).end_of_day

      experiment.update!(state: "selecting", start_date: days_til_start.days.from_now.to_date, end_date: days_til_end.days.from_now.to_date)

      eligible_ids = patient_pool
        .joins(:encounters)
        .where(encounters: {device_created_at: eligibility_start..eligibility_end})
        .where("NOT EXISTS (SELECT 1 FROM encounters WHERE encounters.patient_id = patients.id AND
                encounters.device_created_at > ?)", eligibility_end)
        .left_joins(:appointments)
        .where("NOT EXISTS (SELECT 1 FROM appointments WHERE appointments.patient_id = patients.id AND
                appointments.scheduled_date >= ?)", date)
        .distinct
        .pluck(:id)
      eligible_ids.shuffle!

      total_days.times do
        daily_ids = eligible_ids.pop(PATIENTS_PER_DAY)
        break if daily_ids.empty?
        # TODO: remove references to appointment after removing appointment dependency
        daily_patients = Patient.where(id: daily_ids).includes(:appointments)
        daily_patients.each do |patient|
          group = experiment.group_for(patient.id)
          schedule_reminders(patient, patient.appointments.last, group, date)
          Experimentation::TreatmentGroupMembership.create!(treatment_group: group, patient: patient)
        end
        date += 1.day
      end

      experiment.update!(state: "running")
    end

    protected

    def patient_pool
      Patient.from(Patient.with_hypertension, :patients)
        .contactable
        .where("age >= ?", 18)
        .includes(treatment_group_memberships: [treatment_group: [:experiment]])
        .where(["experiments.end_date < ? OR experiments.id IS NULL", LAST_EXPERIMENT_BUFFER.ago]).references(:experiment)
    end

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
