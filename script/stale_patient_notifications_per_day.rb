#!/bin/ruby

# We are in Tier 2 for WhatsApp, which limits us to 10_000 unique recipients per day
WHATSAPP_LIMIT_PER_DAY = 10_000
# An estimate of how many notifications succeed using WhatsApp
WHATSAPP_SUCCESS_RATE = 0.5
# TBD - this is dependant upon how much margin we want to build in per day for stale patient reminders
# to ensure we stay under the WhatsApp rate limit
STALE_EXPERIMENT_BUFFER = 0.5

active_notifications_scheduled_per_day = Notification.group(:remind_on).count
active_notifications_sent_via_whats_app_per_day = active_notifications_scheduled_per_day * WHATSAPP_SUCCESS_RATE
stale_patients_per_day = (WHATSAPP_LIMIT_PER_DAY - active_notifications_sent_via_whats_app_per_day) * STALE_EXPERIMENT_BUFFER

puts "Estimated amount of patients per day for the stale patient experiment:"
puts stale_patients_per_day
puts
