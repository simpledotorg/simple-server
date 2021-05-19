class BackfillNotifications
  def self.call
    Communication.find_each do |communication|
      unless communication&.appointment&.patient
        Rails.logger.warn "skipping communication #{communcation.id} in the backfill, as there is no related patient"
        next
      end
      notification = communication.build_notification
      notification.message = "#{Notification::APPOINTMENT_REMINDER_MSG_PREFIX}.#{communication.communication_type}"
      notification.subject = communication.appointment
      notification.patient = communication.appointment.patient
      # We are going to assume all past communications have been sent, and their
      # remind_on date should be in the past
      notification.remind_on = communication.created_at
      notification.status_sent!
      notification.save!
    end
  end
end
