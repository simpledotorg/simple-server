class SMSReminderJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  DEFAULT_RETRY_TIMES = 5
  DEFAULT_RETRY_SECONDS = 10.minutes.seconds.to_i

  def perform
    #
    # Get all appointments overdue by 3 days and who have not yet been sms reminded about their overdue visit
    # For each batch of appointments, spin up another job to send a twilio sms to the associated patient
    # for a successful sms, record a followup reminder for the specific kind of reminder
    #
  end

  #
  # Refactor Communication model to support the reminder comm
  # Refactor SMS notification class to accept arbit SMSes
  # Add translations for the SMS
  #
end
