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

      eligible_ids = current_patient_candidates(experiment_start, experiment_end).shuffle!

      experiment_patient_count = (0.01 * percentage_of_patients * eligible_ids.length).round
      eligible_ids = eligible_ids.pop(experiment_patient_count)

      while eligible_ids.any?
        batch = eligible_ids.pop(BATCH_SIZE)
        patients = Patient
          .where(id: batch)
          .includes(:appointments)
          .where(appointments: {scheduled_date: experiment_start..experiment_end})

        patients.each do |patient|
          group = experiment.random_treatment_group
          patient.appointments.each do |appointment|
            schedule_reminders(patient, appointment, group, appointment.scheduled_date)
          end
          group.patients << patient
        end
      end

      experiment.running_state!
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
          group = experiment.random_treatment_group
          schedule_reminders(patient, patient.appointments.last, group, schedule_date)
          group.patients << patient
        end
        schedule_date += 1.day
      end

      experiment.running_state!
    end

    # This is not a scientific experiment like active and stale patient experiments. It does not need or have human study
    # approval and we are not excluding patients under 18 years old. We are leveraging the experimentation framework to
    # request patients to visit clinics to pick up enough blood pressure medication to last the current covid spike.
    # We're using the experimentation framework for two reasons:
    # 1) we want most of the same functionality, including batched daily notification scheduling and the ability to track
    #    results by leveraging the experimentation and notification models
    # 2) this is an excellent opportunity to real-world test the experimentation framework
    def start_medication_reminder_experiment(name, patients_per_day: PATIENTS_PER_DAY)
      experiment = Experimentation::Experiment.find_by!(name: name, experiment_type: "medication_reminder")

      experiment.selecting_state!

      eligible_ids = medication_reminder_patients(experiment)
      if eligible_ids.any?
        eligible_ids.shuffle!

        daily_ids = eligible_ids.pop(patients_per_day)
        daily_patients = Patient.where(id: daily_ids)
        daily_patients.each do |patient|
          group = experiment.random_treatment_group
          schedule_reminders(patient, nil, group, Date.current)
          group.patients << patient
        end
      end

      experiment.running_state!
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

    def medication_reminder_patients(experiment)
      Patient.with_hypertension
        .contactable
        .includes(treatment_group_memberships: [treatment_group: [:experiment]])
        .where("experiments.id IS NULL OR NOT EXISTS (SELECT 1 FROM experiments WHERE experiments.id = ?)", experiment.id).references(:experiment)
        .where(
          "NOT EXISTS (SELECT 1 FROM blood_pressures WHERE blood_pressures.patient_id = patients.id AND blood_pressures.device_created_at > ?)",
          30.days.ago.beginning_of_day
        )
        .distinct
        .pluck(:id)
    end

    def schedule_reminders(patient, appointment, group, schedule_date)
      group.reminder_templates.each do |template|
        remind_on = schedule_date + template.remind_on_in_days.days
        Notification.create!(
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
