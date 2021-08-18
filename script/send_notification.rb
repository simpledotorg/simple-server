#!/usr/bin/env rails runner
#
# Script to send messages via our Twilio notification system.
#
# Provide a patient name as the first argument, and a recipient phone number as the second.
# Note that the patient name must be a real patient in our database - it is only used to
# create a notification for that patient. The phone number provided will be used as the actual recipient,
# and you can use any fully qualified phone number -- including country code.
#
#   script/send_notification.rb "Patient Name" "+1605551234"
#
# To use this from a development box you will need the following in your env before running.
#
# export SIMPLE_SERVER_HOST="api-sandbox.simple.org"
# export TWILIO_PRODUCTION_OVERRIDE=true
# export TWILIO_PHONE_NUMBER="+17044524471"

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
fetched_message = TwilioApiService.new.client.messages(message.sid).fetch
puts "status=#{fetched_message.status}"
puts "Twilio message sid=#{fetched_message.sid} status=#{fetched_message.status}..."
puts
puts "Done!"
