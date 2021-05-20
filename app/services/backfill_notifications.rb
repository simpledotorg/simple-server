class BackfillNotifications
  def self.call
    Communication.find_each do |communication|
      unless communication&.appointment&.patient
        Rails.logger.warn "skipping communication #{communication.id} in the backfill, as there is no related patient"
        next
      end
      next if communication.notification
      notification = communication.build_notification
      notification.message = "#{Appointment::REMINDER_MESSAGE_PREFIX}.#{communication.communication_type}"
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
