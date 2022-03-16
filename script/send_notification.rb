#!/usr/bin/env ruby
#
# Script to send messages via our Twilio notification system.
#
# Provide a patient name as the first argument, and a recipient phone number as the second.
# Note that the patient name must be a real patient in our database - it is used to
# have a patient to hang the notification record off of, and for the full name in the message.
# The phone number provided will be used as the actual recipient,
# and you can use any fully qualified phone number (include the country code).
#
#   script/send_notification.rb "Patient Name" "+1605551234"
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

full_name = ARGV.first || raise(ArgumentError, "You must provide a patient name")
phone_number = ARGV.second || raise(ArgumentError, "You must provide a phone number to receive the message")

puts "Sending a test notification message to #{phone_number}..."

patient = Patient.find_by!(full_name: full_name)
notification = Notification.create!(
  patient: patient,
  remind_on: Date.current,
  status: "scheduled",
  message: "test_message",
  purpose: "test_message"
)
sent_message = AppointmentNotification::Worker.new.perform(notification.id, phone_number)

puts "Twilio message sid=#{sent_message.sid} status=#{sent_message.status}..."
puts "Waiting a second and then refetching Twilio status"
sleep 1
fetched_message = Messaging::Twilio::Api.fetch_message(sent_message.sid)
puts "status=#{fetched_message.status}"
puts "Twilio message sid=#{fetched_message.sid} status=#{fetched_message.status}..."
puts
puts "Done!"
