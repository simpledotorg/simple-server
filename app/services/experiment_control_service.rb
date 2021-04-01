class InvalidExperiment < StandardError; end
module ExperimentControlService
  def self.start_current_patient_experiment(name, percentage_of_patients, delay_start=5)
    # error if percentage_of_patients is > 100
    existing_experiment = Experimentation::Experiment.where(experiment_type: "current_patient_reminder", state: ["selecting", "live"])
    raise InvalidExperiment if existing_experiment.any?

    experiment = Experimentation::Experiment.find_by!(name: name, experiment_type: "current_patient_reminder")
    percentage_of_patients = Integer(percentage_of_patients)
    experiment_start = delay_start.days.from_now.beginning_of_day
    experiment_end = (experiment_start + 30.days).end_of_day

    experiment.state_selecting!

    eligible = patient_pool
      .joins(:appointments)
      .where("appointments.status = ?", "scheduled")
      .where("appointments.scheduled_date BETWEEN ? AND ?", experiment_start, experiment_end)
      .order(Arel.sql("random()"))
    experiment_patient_count = (0.01 * percentage_of_patients * eligible.length).round
    experiment_patients = eligible.take(experiment_patient_count)
    experiment_patients.each do |patient|
      group = experiment.group_for(patient.id)
      appointment = patient.appointments.where(status: "scheduled")
        .where("appointments.scheduled_date BETWEEN ? AND ?", experiment_start, experiment_end).first
      schedule_reminders(patient, appointment, experiment, group, appointment.scheduled_date)
      Experimentation::TreatmentGroupMembership.create!(treatment_group: group, patient: patient)
    end

    experiment.update!(state: "live", start_date: experiment_start, end_date: experiment_end)
  end

  # consider adding a total days and # per day args
  def self.start_stale_patient_experiment(name)
    experiment = Experimentation::Experiment.find_by!(name: name, experiment_type: "stale_patient_reminder")
    date = Date.current
    eligibility_start = (date - 365.days).beginning_of_day
    eligibility_end = (date - 35.days).end_of_day

    experiment.state_selecting!

    eligible_patients = patient_pool
      .joins(:encounters)
      .where("encounters.device_created_at BETWEEN ? AND ?", eligibility_start, eligibility_end)
      .where("NOT EXISTS (SELECT 1 FROM encounters as e2 WHERE e2.patient_id = patients.id AND
              e2.device_created_at > ?)", eligibility_end)
      .left_joins(:appointments)
      .where("NOT EXISTS (SELECT 1 FROM appointments as a2 WHERE a2.patient_id = patients.id AND
              a2.scheduled_date > ?)", eligibility_end)
      .order(Arel.sql("random()"))
      .to_a

    30.times do
      daily_patients = eligible_patients.pop(10_000)
      break if daily_patients.empty?
      daily_patients.each do |patient|
        group = experiment.group_for(patient.id)
        appointment = patient.appointments.where(status: "scheduled").last # i think this should suffice
        schedule_reminders(patient, appointment, experiment, group, date)
        Experimentation::TreatmentGroupMembership.create!(treatment_group: group, patient: patient)
      end
      date += 1.day
    end
    experiment.update!(state: "live", start_date: Date.current, end_date: Date.current + 30.days)
  end

  protected

  def self.patient_pool
    Patient.from(Patient.with_hypertension, :patients)
      .contactable
      .where("age >= ?", 18)
      .includes(treatment_group_memberships: [treatment_group: [:experiment]])
      .where(["experiments.end_date < ? OR experiments.id IS NULL", 14.days.ago]).references(:experiment)
  end

  def self.schedule_reminders(patient, appointment, experiment, group, schedule_date)
    group.reminder_templates.each do |template|
      remind_on = schedule_date + template.appointment_offset.days
      AppointmentReminder.create!(
        remind_on: remind_on,
        status: "pending",
        message: template.message,
        experiment: experiment,
        reminder_template: template,
        appointment: appointment,
        patient: patient
      )
    end
  end
end
