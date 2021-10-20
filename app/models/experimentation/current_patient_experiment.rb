module Experimentation
  class CurrentPatientExperiment < Experiment
    include Memery

    MAX_PATIENTS_PER_DAY = 2000

    def initialize(experiment, date)
      @experiment = experiment
      @date = date
    end

    def enroll_patients
      patients = select_patients(@date.beginning_of_day, @date.end_of_day).limit(MAX_PATIENTS_PER_DAY)

      patients.in_batches(of: 1_000).each do |patient|
        group = @experiment.random_treatment_group
        group.enroll(patient)
      end
    end

    memoize def enrolled_patients
      @experiment.patients # where not visited, not completed, not rejected etc
    end

    def monitor
      # for enrolled_patients
      mark_visits
      evict_patients
      send_notifications
    end

    def mark_visits
    end

    def evict_patients
    end

    def send_notifications
    end

    private

    def select_patients(scheduled_appointment_start_time, scheduled_appointment_end_time)
      Experiment.candidate_patients
        .joins(:appointments)
        .merge(Appointment.status_scheduled)
        .where("appointments.scheduled_date BETWEEN ? and ?", scheduled_appointment_start_time, scheduled_appointment_end_time)
        .distinct
    end
  end
end
