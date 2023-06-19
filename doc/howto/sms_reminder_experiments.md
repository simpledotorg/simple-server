# Running SMS reminder experiments

## Prerequisites
To start an SMS experiment you'll need to gather information about the following:

#### Experiment

- `name` - A name for the experiment.
- `experiment_type` - There are two kinds of experiments depending on the type of the patients that will be enrolled.
  - `current_patients` - Patients who have an upcoming appointment.
  - `stale_patients` - Patients who have not visited in the last year and do not have a scheduled appointment in the future.
- `max_patients_per_day` - The maximum number of patients to be enrolled per day.
- `start_time` - Enrollments will begin at this point in time.
- `end_time` - Enrollments will stop at this point in time.
- `filters` - A hash of mutually exclusive `include/exclude` filters for `states`, `blocks` & `facilities`.

#### Treatment Groups

- The different buckets which patients will be assigned to in the experiment.
  Each treatment group will have a different content or frequency of messages sent to it.
- You will probably also need a `control` group that doesn't receive any messages as a baseline.

#### Reminder templates

- The content and frequency of messages in each `treatment_group` is determined by it's `reminder_templates`.
  Each reminder template has
  - a `message` - The locale key of the message (for ex. `notifications.set01.basic`).
  - a `remind_on` -  The day on which this message will be sent out relative to the expected date of return.
  - The `message` texts must be added to `config/locales/notifications/`.
- Reminder templates are classified in 3 sets defined as follows:
  - `set01` is for upcoming appointments.
  - `set02` is for patients having appointment on the same day of the notification.
  - `set03` is for patients(current or stale) who have missed appointments.

For India:
- If the experiment has new messages and translations you'll need to get them [approved by DLT](doc/howto/bsnl/sms_reminders.md) and make sure they're present in
  [config](../config/data/bsnl_templates.yml). See [bsnl/sms_reminders.md](bsnl/sms_reminders.md)

As an example, if you want to run this 3-message cascade for current patients
- A reminder is sent 1 day before an upcoming appointment
- A reminder is sent on the day of the appointment
- A reminder is sent 1 day after the appointment

these reminder templates need to be setup:

```ruby
treatment_group = experiment.treatment_groups.create!(description: "basic_cascade")
treatment_group.reminder_templates.create!(message: "notifications.set01.basic", remind_on_in_days: -1)
treatment_group.reminder_templates.create!(message: "notifications.set02.basic", remind_on_in_days: 0)
treatment_group.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 1)
```

For current patients, the `remind_on` is set relative to the date they are expected to return.
For stale patients, it's relative to the date of enrollment in the experiment.

## Setup
- Enable the `experiment` and `notifications` flipper flags.
- You'll need to create the `experiment`, its `treatment_groups` and `reminder_templates`. See [appendix](#appendix) for sample commands.
- You can also put these commands in a data migration in the style of [this data migration](db/data/20220412130957_create_apr2022_ihci_experiment.rb) 
instead of running them from rails console.

**Note about consecutive experiments**

Make sure there's always a gap of at least these many days between two experiments (if this value is positive)
```ruby
experiment_1.earliest_remind_on - experiment_2.earliest_remind_on
```

An experiment that sends notifications before an appointment enrolls patients who have appointments in the future.
For an experiments that starts immediately after such an experiment, this can mean that patients in the first few days might've already been enrolled in the first one.
This causes low enrollments in the second experiment.

## Running the experiment

A cron in `schedule.rb` orchestrates the experiment. It runs a set of tasks everyday.
When an experiment starts, you should
- Check in on the metabase dashboards ([IHCI](https://metabase.simple.org/dashboard/54-notifications-experiment-generic-dashboard),
  [Bangladesh](https://metabase.bd.simple.org/dashboard/10-notifications-experiment-generic-dashboard))
  every once in a while.
- We get a daily summary on slack on #ab-testing-stats. Check on the "Pending notifications" report everyday. 
  This number should always be 0. If not, some reminder messages are not being sent to patients and this problem requires investigation.
  Inspect error reports in [Sentry](https://sentry.io/organizations/resolve-to-save-lives/issues/?project=1217715) to find and fix the problem.
- Run `deploy:rake task="bsnl:get_account_balance"` every once in a while, check the balance and recharge if needed.

**Notes**

- Depending on the cadence, notifications may go out for a few days after the experiment has "ended".
- Visits are monitored and patients are evicted until 15 days (`MONITORING_BUFFER`) from the last enrollment date.
- Monitoring includes:
  - Recording the statuses of notifications
  - Marking visits for patients who returned to care
  - Evicting patients who have invalid data
- Reasons for eviction:
  - appointment_moved - the appointment was rescheduled or patient agreed to visit on a later date. This makes the
  `days_to_visit` calculation dubious so we just evict the patient.
  - new_appointment_created_after_enrollment
  - notification_failed
  - patient_soft_deleted

### Important links

- [IHCI metabase dashboard](https://metabase.simple.org/dashboard/54-notifications-experiment-generic-dashboard)
- [Bangladesh metabase dashboard](https://metabase.bd.simple.org/dashboard/10-notifications-experiment-generic-dashboard)
- [IHCI CSV export](https://metabase.simple.org/question/496-a-b-experiments-statistical-analysis-report)
- [Bangladesh CSV export](https://metabase.bd.simple.org/question/132-a-b-experiments-nhf-statistical-analysis-report)

If you're adding any new reports to the IHCI dashboard save them in this [collection](https://metabase.simple.org/collection/43-a-b-testing-ihci-shared)
so it's viewable by other people.

### Cancelling an experiment
You might want to cancel an experiment because of
- issues with the setup/data consistency
- issues with sending notifications

In that case you can run
```ruby
Experimentation::NotificationsExperiment.find("experiment id").cancel
```

This will soft-delete the experiment, which means it will not enroll, notify and monitor anymore.
If you want to only stop enrolling but notify and monitor the remaining patients,
change the `end_time` of the experiment.

## In the long run

- When we decide on a message format and start sending a single message eventually, the current plan
  is to run an "experiment" with a single bucket. Although, a patient can be enrolled in an experiment only once.
  A single long running experiment will hence not work for patients who need to follow up every month.
  A new experiment will need to be started every month.
- The `treatment_group_memberships` and `notifications` tables are fast growing. 
  We will have to think about [archiving them frequently](https://app.shortcut.com/simpledotorg/story/7931/data-archival-strategy-for-notification-communication-and-delivery-detail-records)
  once we start doing regular notifications.

## Appendix

Creating a sample experiment
```ruby
start_time = Date.parse("6 May 2023").beginning_of_day
end_time = Date.parse("6 May 2023").beginning_of_day
filters = {
        "states" => {"include" => ["Himachal Pradesh", "Maharashtra"]},
        "blocks" => {"exclude" => ["uuid-1", "uuid-2"]},
        "facilities" => {"exclude" => ["uuid-3", "uuid-4"]}
}

# Creating an experiment that targets patients with upcoming visits.
e = Experimentation::Experiment.create!(
  name: "Current Patient May 2023 Official Short",
  experiment_type: "current_patients",
  start_time: start_time,
  end_time: end_time,
  max_patients_per_day: 20000,
  filters: filters
)
# Create treatment groups. This group has 2 messages sent 3 days before and
# 7 days after visit.
cascade_tg = e.treatment_groups.create!(description: "official_short_cascade")
cascade_tg.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: -3)
cascade_tg.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 7)
# This group sends 1 message on the day of visit.
single_tg = e.treatment_groups.create!(description: "official_short_single")
single_tg.reminder_templates.create!(message: "notifications.set02.official_short", remind_on_in_days: -3)

# Creating a stale patient experiment
e = Experimentation::Experiment.create!(
  name: "Stale Patient May 2023 Official Short",
  experiment_type: "stale_patients",
  start_time: start_time,
  end_time: end_time,
  max_patients_per_day: 20000,
  filters: filters
)
tg = e.treatment_groups.create!(description: "official_short_cascade")
tg.reminder_templates.create!(message: "notifications.set02.official_short", remind_on_in_days: 0)
tg.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 7)
```
