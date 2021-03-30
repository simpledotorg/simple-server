module ExperimentControlService

  def self.start_current_patient_experiment(name, percentage_of_patients, delay_start=5)
    # error if percentage_of_patients is > 100
    experiment = Experimentation::Experiment.find_by!(name: name, experiment_type: "current_patient_reminder")
    percentage_of_patients = Integer(percentage_of_patients)
    experiment_start = Date.current + delay_start.days
    experiment_end = experiment_start + 30.days
    experiment.update(state: "selecting")
    eligible = patient_pool
      .joins(:appointments)
      .where("appointments.status = ?", "scheduled")
      .where("appointments.scheduled_date BETWEEN ? AND ?", experiment_start, experiment_end)
      .order(Arel.sql("random()"))
    experiment_patient_count = (0.01 * percentage_of_patients * eligible.length).round
    experiment_patients = eligible.take(experiment_patient_count)
    experiment_patients.each do |patient|
      group = experiment.group_for(patient.id)
      appointment = patient.appointments.where(status: "scheduled").where("appointments.scheduled_date BETWEEN ? AND ?", experiment_start, experiment_end).limit(1).first
      schedule_reminders(patient, appointment, experiment, group, appointment.scheduled_date)
      Experimentation::TreatmentGroupMembership.create!(treatment_group: group, patient: patient)
    end
    experiment.update(state: "live", start_date: experiment_start, end_date: experiment_end)
  end

  def self.start_stale_patient_experiment(name, max_patients = 300_000)
    experiment = Experimentation::Experiment.find_by!(name: name, experiment_type: "stale_patient_reminder")
    eligibility_start = (Date.current - 365.days).beginning_of_day
    eligibility_end = (Date.current - 35.days).end_of_day
    eligible_patients = patient_pool
      .joins(:appointments)
      .where("appointments.status = ?", "scheduled")
      .where("appointments.scheduled_date BETWEEN ? AND ?", eligibility_start, eligibility_end)
      .limit(max_patients)
      .order(Arel.sql("random()"))
    selectable_patients = eligible_patients.to_a
    date = Date.current
    30.times do
      schedule_patients = selectable_patients.pop(10_000)
      break if schedule_patients.empty?
      schedule_patients.each do |patient|
        group = experiment.group_for(patient.id)
        appointment = patient.appointments.where(status: "scheduled").last # i think this should suffice
        schedule_reminders(patient, appointment, experiment, group, date)
        Experimentation::TreatmentGroupMembership.create!(treatment_group: group, patient: patient)
      end
      date += 1.day
    end
    experiment.update(state: "live", start_date: Date.current, end_date: Date.current + 30.days)
  end

  protected

  def self.patient_pool
    Patient.from(Patient.with_hypertension, :patients)
      .where(reminder_consent: "granted")
      .where.not(status: "dead")
      .joins(:phone_numbers)
      .merge(PatientPhoneNumber.phone_type_mobile.unscoped)
      .where("age >= ?", 18)
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
