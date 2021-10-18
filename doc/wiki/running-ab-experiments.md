# Running AB Experiments

## Experiment setup:
- experiments can be set up by adding a data migration to `db/data`
- an example of how to set up an experiment can be found in `lib/seed/experiment_seeder.rb`
- the `experiment` feature flag must be on before the patient selection process and while experiment notifications are still sending. Turning it off will prevent patient selection and experiment notifications from being scheduled to send each day.
- in India, the `whatsapp_appointment_reminders` feature flag should also be turned on because WhatsApp notifications are of higher value than SMS.

## Current patient experiment:
- current patient experiments can start sending notifications before the experiment start date. The start date and end date truly mean "selection start date" and "selection end date". Patients are selected for the experiment if they have appointments during the date range. But because reminder templates can be configured to send notifications before or after appointments, it's possible for notifications to be sent before the start date and after the end date. For the experiment to run correctly, the experiment must be created and added to scheduler before notifications should start sending, not just before the experiment start_time.
- experiments must first be created according to [experiment setup](#experiment-setup).
- experiments will be run by adding the following to `config/schedule.rb`:
  - `runner "Experimentation::Runner.start_current_patient_experiment(name: 'experiment name')"`
  - this also accepts an optional `percentage_of_patients` argument that defaults to 100
- the first time it is run by the scheduler, the job will:
  - select eligible patients
  - assign them randomly to treatment groups
  - create all notifications for experiment patients, based on the date of their next appointment and the information in their treatment group's reminder templates. These will be marked as "pending" and will not be sent by this job.
  - change the experiment state from "new" to "running"
- those messages will then be scheduled for delivery each day as described [here](notification-scheduling).
- despite the fact that patient selection and notification creation is all done during the first time it runs, this experiment runner can safely be left on the scheduler. On subsequent runs, it will do nothing until the experiment end date has passed, at which point it will change the experiment state to "complete".

## Stale patient experiment:
- stale patient selection occurs daily every day from experiment start date through experiment end date.
- experiments must first be created according to [experiment setup](#experiment-setup).
- experiments will be run by adding the following to `config/schedule.rb`:
  - `runner "Experimentation::Runner.schedule_daily_stale_patient_notifications(name: 'experiment name', patients_per_day: 2000)"`
  - the `patients_per_day` argument is optional and defaults to 10,000
- each day of the experiment, this job will:
  - select the specified number of patients
  - assign them randomly to treatment groups
  - create notifications appropriate for their group. These notifications will be marked as "pending" and will not be sent at this time.
  - set the experiment state to "running"
- those messages will then be scheduled for delivery each day as described [here](notification-scheduling).
- after the experiment end date has passed, the job will change the experiment state to "complete" and it will stop adding new patients on subsequent runs.

## Notification scheduling
- notifications are scheduled to be sent daily by a job that should be added to `config/schedule.rb`:
  - `runner "AppointmentNotification::ScheduleExperimentReminders.perform_now"`
- it will search for any notifications with a `remind_on` of today and a `status` of "pending", change the notification status to "scheduled", and schedule a sidekiq worker to send the notification during the notification window
- in India, text messages will first be sent as WhatsApp messages. If the WhatsApp message fails, we will resend the message as SMS.
- in Bangladesh, text messages will first be sent as Imo messages. If the Imo message fails, we will resend the message as SMS.

## Experiment monitoring
- a developer with production access should be assigned to monitor the patient selection and notification sending process. That developer should:
  - monitor sentry for errors
  - monitor the notifications metabase dashboard
  - monitor the datadog notifications module dashboard: https://app.datadoghq.com/logs?query=%40module%3Anotifications&cols=core_host%2Ccore_service&index=%2A&messageDisplay=inline&stream_sort=desc
  - monitor the datadog notifications metrics dashboard: https://app.datadoghq.com/dashboard/2gr-37g-7sh?from_ts=1627496327194&to_ts=1628101127194&live=true

## Experiment cleanup:
- the experiment runner jobs in the scheduler will change the experiment status to "complete" after the end date has passed. This will not prevent scheduled notifications from being sent.
- it's important to note that notifications can be scheduled beyond the experiment end date due to the cascading nature of notifications. The end date is used by the selection process and not to prevent notifications from being sent.
- to prevent notifications from being sent, see instructions [here](#ending-an-experiment-early).

## Ending an experiment early
- the fastest way to stop experiment notifications from sending is to turn off the `experiment` and `notifications` feature flag. This is an option if we want to pause the experiment but not end it. Turning off `notifications` will turn off all notifications, not just experiment notifications.
- if we need to end an experiment early, we can do it by running `Experimentation::Runner.abort_experiment("experiment name")`. This will:
  - change the experiment state to "cancelled"
  - mark all "pending" and "scheduled" notifications as "cancelled"
- notifications that have already been scheduled to send will not send if either the experiment or the notification is cancelled
