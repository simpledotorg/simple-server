# Sending non-experimental sms reminders

## Sms reminders and experiments

- Sms reminders are sent to notify patients about their upcoming/missed appointments or to bring them back into care if
  they haven't returned in a while
- We have experimented with different messaging templates and strategies in each country to figure out what gets back
  people
  into care most effectively using the experiments model.
- Once these are finalised, we set up sms reminders to notify patients month on month without any further
  experimentation.
- As of now however, if we want to send sms reminders that are **not** part of any experiment, we can only set them up
  through the experiment model. There is a
  [missed visit service](https://github.com/simpledotorg/simple-server/blob/171a0c27fb84468987c1c01126ef6c5dcaf45515/app/services/missed_visit_reminder_service.rb)
  that can send an sms on a day relative to the appointment, which can be run daily from within a scheduled rake task
  but if we want to send a cascade of smses, which is usually the case, experiments are the quickest way to set them up.
  There is a lot of overhead to this (see: [In the long run](#in-the-long-run)) and should eventually be refactored.
- As of Jan 30 2024, we are sending sms reminders in Sri Lanka, India and Bangladesh. We don't run sms reminder
  experiments in any of these countries. This could change in the future.

## Before setting up sms reminders

- Since we usually set these up for multiple months at a time, it's good practice to check with the team (on the
  #sms-patient-reminders Slack channel) if the regions we're sending smses in are up to date, and if we want to continue
  sending sms reminders for the next x months in that country.
    - In Bangladesh, due to drug shortages, we want to update the region list every quarter. So we would set these up
      to run for 3 months at a time and coordinate with Dr. Reena for the updated list of regions.
- Configurations for sms reminders - when to send the reminders and what template to use - don't usually change once
  experimentation has ended. You can find the latest configuration for each country in the latest data migration or
  in the experiment's `treatment_groups` and `reminder_templates` tables in the database.
- You can set up Slack reminders for a week before the current set of "experiments" ends on #sms-patient-reminders so
  that there is enough time to set up the next set of experiments and get the code reviewed and merged. It would be good
  to automate this eventually.

## Setup

- Check that the `experiment` and `notifications` Flipper flags are enabled.
- Add a data migration file to create the experiments, their treatment groups and reminder templates. This way we can
  keep track of changes made and rollback changes if necessary.
- Ensure that the data migration only runs in the correct country/ies and environment/s using appropriate checks.
- How to set up sms reminder
  experiments: https://github.com/simpledotorg/simple-server/blob/171a0c27fb84468987c1c01126ef6c5dcaf45515/doc/howto/sms_reminder_experiments.md
