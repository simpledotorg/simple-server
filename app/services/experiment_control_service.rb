class ExperimentControlService
  LAST_EXPERIMENT_BUFFER = 14.days.freeze
  PATIENTS_PER_DAY = 10_000

  class << self
    def start_current_patient_experiment(name, days_til_start, days_til_end, percentage_of_patients = 100)
      experiment = Experimentation::Experiment.find_by!(name: name, experiment_type: "current_patient_reminder")
      experiment_start = days_til_start.days.from_now.beginning_of_day
      experiment_end = days_til_end.days.from_now.end_of_day

      experiment.update!(state: "selecting", start_date: experiment_start.to_date, end_date: experiment_end.to_date)

      eligible = patient_pool
        .joins(:appointments).merge(Appointment.status_scheduled)
        .where("appointments.scheduled_date BETWEEN ? AND ?", experiment_start, experiment_end)
        .order(Arel.sql("random()"))

      experiment_patient_count = (0.01 * percentage_of_patients * eligible.length).round
      experiment_patients = eligible.take(experiment_patient_count)

      experiment_patients.each do |patient|
        group = experiment.group_for(patient.id)
        appointments = patient.appointments.status_scheduled.between(experiment_start, experiment_end)
        appointments.each do |appointment|
          schedule_reminders(patient, appointment, group, appointment.scheduled_date)
        end
        Experimentation::TreatmentGroupMembership.create!(treatment_group: group, patient: patient)
      end

      experiment.update!(state: "live", start_date: experiment_start, end_date: experiment_end)
    end

    def start_stale_patient_experiment(name, total_days)
      experiment = Experimentation::Experiment.find_by!(name: name, experiment_type: "stale_patient_reminder")
      date = Date.current
      eligibility_start = (date - 365.days).beginning_of_day
      eligibility_end = (date - 35.days).end_of_day

      experiment.state_selecting!

      eligible_patients = patient_pool
        .joins(:encounters)
        .where("encounters.device_created_at BETWEEN ? AND ?", eligibility_start, eligibility_end)
        .where("NOT EXISTS (SELECT 1 FROM encounters WHERE encounters.patient_id = patients.id AND
                encounters.device_created_at > ?)", eligibility_end)
        .left_joins(:appointments)
        .where("NOT EXISTS (SELECT 1 FROM appointments WHERE appointments.patient_id = patients.id AND
                appointments.scheduled_date >= ?)", date)
        .order(Arel.sql("random()"))
        .to_a

      total_days.times do
        daily_patients = eligible_patients.pop(PATIENTS_PER_DAY)
        break if daily_patients.empty?
        daily_patients.each do |patient|
          group = experiment.group_for(patient.id)
          appointment = patient.appointments.where(status: "scheduled").last
          schedule_reminders(patient, appointment, group, date)
          Experimentation::TreatmentGroupMembership.create!(treatment_group: group, patient: patient)
        end
        date += 1.day
      end

      experiment.update!(state: "live", start_date: Date.current, end_date: total_days.days.from_now.to_date)
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
