#!/bin/ruby

# We are in Tier 2 for WhatsApp, which limits us to 10_000 unique recipients per day
WHATSAPP_LIMIT_PER_DAY = 10_000
# TBD - this is dependant upon how much margin we want to build in per day for stale patient reminders
# to ensure we stay under the WhatsApp rate limit
STALE_EXPERIMENT_BUFFER = 0.5


active_notifications_scheduled_per_day = Notification.group(:schedule_date).count
active_notifications_sent_via_whats_app_per_day = active_notifications_scheduled_per_day * .50
(WHATSAPP_LIMIT_PER_DAY - active_notifications_sent_via_whats_app_per_day) * STALE_EXPERIMENT_BUFFER