#!/usr/bin/env ruby
#
# Script to send messages via our Twilio notification system.
#
# Provide a patient ID as the argument.
# This will find the patient and hang the notification record to it.
# The patient's latest mobile number provided will be used as the actual recipient,
# and they can have any fully qualified phone number (include the country code).
#
#   script/send_notification.rb "<patient-uuid>"
#
# To send real messages from Sandbox, set the following first:
#
# export TWILIO_PRODUCTION_OVERRIDE=true
#
# To send real messages from development, set the following first:
#
# export SIMPLE_SERVER_HOST="api-sandbox.simple.org"
# export TWILIO_ACCOUNT_SID=[production SID here]
# export TWILIO_AUTH_TOKEN=[production auth token here]
# export TWILIO_PHONE_NUMBER="+17044524471"
# export TWILIO_PRODUCTION_OVERRIDE=true

require_relative "../config/environment"

id = ARGV.first || raise(ArgumentError, "You must provide a patient ID")
patient = Patient.find_by!(id: id)
puts "Sending a test notification message to #{patient.latest_mobile_number}..."

notification = Notification.create!(
  patient: patient,
  remind_on: Date.current,
  status: "scheduled",
  message: "test_message",
  purpose: "test_message"
)
sent_message = AppointmentNotification::Worker.new.perform(notification.id)

puts "Twilio message sid=#{sent_message.sid} status=#{sent_message.status}..."
puts "Waiting a second and then refetching Twilio status"
sleep 1
fetched_message = Messaging::Twilio::Api.fetch_message(sent_message.sid)
puts "status=#{fetched_message.status}"
puts "Twilio message sid=#{fetched_message.sid} status=#{fetched_message.status}..."
puts
puts "Done!"
