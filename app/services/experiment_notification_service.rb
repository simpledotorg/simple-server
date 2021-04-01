class ExperimentNotificationService
  def initialize(experiment:)
    @patients = experiment.patients
  end

  def send_notifications
    eligible_appointments = appointments.where(experiment: experiment)

    eligible_appointments.each do |appointment|
      message_available = experiment.queueable_message_exists?(appointment.patient, Date.today)

      if message_available
        ExperimentNotification::Worker.perform_at(time, message, appointment.patient)
      end
    end
  end
end
