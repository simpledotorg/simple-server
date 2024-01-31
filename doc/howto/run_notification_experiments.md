# Guide to running notification experiments

This document is a guide on how to set up and manage experiments based on sms reminders. For simply sending sms reminders, see the [sms reminders how-to guide](doc/howto/sms_reminders.md) first.

## Setting up an experiment

To set up an experiment, you have to create an experiment object, its treatment groups and its reminder templates. Generally, both current and stale patient experiments are set up together (see: experiment_type below). But you can set up either one based on your requirement.

See note on [setting up consecutive experiments](#consecutive-experiments)

Also see note on [adding a notification dashboard](#notification-dashboard-in-a-new-environment) when setting up experiments in a new environment

### Steps
- Ensure that the `experiment` and `notifications` Flipper flags are enabled in your experiment's environment
- Create the [experiment](#experiment), its [treatment groups](#treatment-groups) and its [reminder templates](#reminder-templates)
  - See [appendix](#appendix) for an example
  - Ideally, create these via a data migration to keep track of changes made and to be able to rollback changes in case of errors
    - See [example data migration](TODO)
    - Ensure that the data migration only runs in the correct country/ies and environment/s using appropriate checks.

### Components
#### Experiment

See note on [experiment duration](#experiment-duration)

- **name**: _A name for the experiment_
  - Convention is `<experiment type> <month> <year>`. eg: "Current patients Feb 2024"
  - This is so we have a uniquely and easily identifiable name for each experiment
- **experiment_type**: _Depending on the type of patients that will be enrolled_
  - current_patients: Patients who have an upcoming appointment
  - stale_patients: Patients who have not visited for a while (usually 35 to 365 days since their last visit) and do not have a scheduled appointment in the future.
- **max_patients_per_day**: _The maximum number of patients to be enrolled per day_
  - For current patient experiments, this value should be well above the average number of daily appointments in that environment so that all eligible patients get reminders
  - For stale patient experiments:
    - This is to stagger the messages over the course of the experiment so as to not overwhelm clinics with many patients coming to a clinic on the same day
    - The entire stale patient pool should be rotated through within the experiment duration, so if you there are 1000 stale patients in the system, max_patients_per_day = total_stale_patients/experiment_duration = 1000/30 = ~ 33 patients
    - A nice side effect of this is that since the pool of eligible patients is usually way larger, this cap enables up to consistently manage our messaging costs
  - Usually, you can set the higher of the two for both experiment types
- **start_time**: _Enrollments will begin at this point in time_
  - A note on experiment timelines can be found [here](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/019-ab-testing-enhancements.md#experiment-timeline)
  - As far as possible, set up experiments to start at the beginning of the month. It will be easier to keep track of and manage experiments this way.
- **end_time**: _Enrollments will stop at this point in time_
- **filters**: _Regions to send notifications in_
  - This field is a hash of mutually exclusive `include/exclude` region filters for `states`, `blocks` & `facilities`.
  - For an example requirement to send smses to patients in all facilities in block `block-A` except `facility-B`
    and `facility-C`, filters would look like:
    ```ruby
    filters = {
    "blocks" => {"include" => ["block-A"]},
    "facilities" => {"exclude" => ["facility-B", "facility-C"]}
    }
    ```
  - Note that `states` expects an array of state names, `blocks` expects an array of block IDs, and `facilities` expects an array of facility slugs. This should change in the future.

#### Treatment Groups

- Treatment groups are the different buckets to which patients will be assigned in an experiment. Each treatment group will have a different message content or frequency of messages sent to it.
- You will probably also need a `control` group that doesn't receive any messages to have a baseline for your experiment.
- Note: For [non-experimental sms reminders](doc/howto/sms_reminders.md), there are no treatment groups as such since we send the same messages to all patients. But since we define our requirements in terms of treatment groups, we set up a single treatment group and add all the reminder templates to it.

#### Reminder templates

The content and frequency of messages in each `treatment_group` is defined by its `reminder_templates`. Each reminder template has the following fields:
- **message**: The locale key of the message template
  - Format is `notifications.<set-number>.<message-type>`. Example: "notifications.set01.basic"
  - Message templates for reminder templates are classified into the following 3 sets:
    - `set01` for when the appointment is coming up
    - `set02` for when the appointment is on the same day as the notification
    - `set03` for when the appointment has passed
  - The message template texts can be found in `config/locales/notifications/`
  - See note on [adding new message templates](#adding-new-message-templates)
- **remind_on**: The day on which this message will be sent relative to the expected date of return
  - This is an integer value: -1 to send a notification 1 day before the appointment, 0 to send it on the appointment date, 3 to send it 3 days after the appointment
  - Be sure to use the correct message set number based on your remind_on value so that the patient sees a meaningful message when they receive the notification.
  - The expected date of return is different for current and stale patient experiments. See: [here](https://github.com/simpledotorg/simple-server/blob/master/app/models/experimentation/stale_patient_experiment.rb#L11)

**Example code**: If you want to run this 3-message cascade for current patients:
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

## Running the experiment

A cron in `schedule.rb` orchestrates the experiment. Every day, it enrolls, monitors and schedules notifications for eligible patients
- See note on [experiment monitoring](#experiment-monitoring)

When an experiment starts, you should
- Check in on the metabase dashboards ([IHCI](https://metabase.simple.org/dashboard/54-notifications-experiment-generic-dashboard), [Bangladesh](https://metabase.bd.simple.org/dashboard/10-notifications-experiment-generic-dashboard)) every once in a while
  - See: [important links](#important-links)
- Currently we get a daily summary of running experiments on the #ab-testing-stats Slack channel
  - See note on [what to watch out for](#things-to-keep-an-eye-on-in-ab-testing-stats) in these stats
- Sms account balance
  - We have daily cron jobs running to check the account balance for sms providers that don't allow recurring recharge. Alerts are in the process of being configured to automate this. Use Slack reminders as a stopgap.
  - See [this doc](https://docs.google.com/document/d/1zvKya0xtSXjnvC9RlUDEbFXO6xQGRTZ8J1xElcgpTlo/edit#heading=h.sqmvjkylmtqy) on how to make recharges for each country
- See note on why notifications sometimes [continue to go out after an experiment has "ended"](#notifications-go-out-after-experiment-has-ended)

## Cancelling an experiment
You might want to cancel an experiment because of
- issues with the setup/data consistency
- issues with sending notifications

You can do the following:
- To soft-delete the experiment, meaning it will not enroll, notify and monitor anymore, run:
  ```ruby
  Experimentation::NotificationsExperiment.find("<experiment-id>").cancel
  ``` 
- If you want to only stop enrolling but continue to notify and monitor the remaining patients, change the `end_time` of the experiment.
- If you want to quickly pause the experiment without any deployment and without cancelling the experiment, disable the `experiments` Flipper flag

## In the long run
TODO: Put this in a story card

- The `treatment_group_memberships` and `notifications` tables are fast growing. We will have to think about [archiving them frequently](https://app.shortcut.com/simpledotorg/story/7931/data-archival-strategy-for-notification-communication-and-delivery-detail-records) once we start doing regular notifications.

## Footnotes
Addendums the rest of this document points to.

### Setting up consecutive experiments

Ensure there's always a gap of at least these many days between two experiments (if this value is positive)
```ruby
experiment_1.earliest_remind_on - experiment_2.earliest_remind_on
```

An experiment that sends notifications before an appointment enrolls patients who have appointments in the future. For an experiments that starts immediately after such an experiment, this can mean that patients in the first few days might've already been enrolled in the first one. This causes low enrollments in the second experiment.

### Adding new message templates
- If your experiment requires a new template, check with your team to get the appropriate translations done
- Add the new message template and its translations to `config/locales/notifications/`
- For India specifically: If the experiment has new messages and translations you'll need to get them [approved by DLT](doc/howto/bsnl/sms_reminders.md) and make sure they're present in
  [config](../config/data/bsnl_templates.yml). See [bsnl/sms_reminders.md](bsnl/sms_reminders.md)

### Notification dashboard in a new environment
We want to monitor experiments during and after their run to ensure they are running as expected. When you're starting experiments in a new country/environment, import the existing [IHCI metabase dashboard](https://metabase.simple.org/dashboard/54-notifications-experiment-generic-dashboard) to its Metabase instance. Ensure that everything is working correctly.

If you're adding any new reports to the IHCI dashboard save them in [this collection](https://metabase.simple.org/collection/43-a-b-testing-ihci-shared) so it's viewable by other people.

### Why experiments are set up to run for a month

After a patient visits, they are marked as visited. Their visit information is captured and they aren’t notified again for the remainder of the experiment. However, patients generally have follow up appointments repeating every 30 days. Currently experiments are designed to send reminders for one appointment, so to continuously send appointment reminders to patients, experiments are set up to run for upto 1 month.

This is not enforced in the code anywhere but is good practice.

#### Experiment duration for non-experimental notification reminders

See: [non-experimental sms reminders](https://github.com/simpledotorg/simple-server/blob/050ed4c4270768feb3243c7489ef29e81115b756/doc/howto/sms_reminders.md)

We usually want to send the same messages to patients every appointment, but since these can only be set up through experiments, we are constrained to set up sms reminders by month. This is why we usually set them up for multiple months at a time.

### Things to keep an eye on in #ab-testing-stats
Ideally, we want to move all of this to automated alerts
- The "Pending notifications" report
  - This number should be zero or close to zero everyday
  - This is usually a good place to catch a majority of issues with our experiments, because if messages are not being sent then the sms provider has an issue or the code does or something in between is broken 
  - Inspect error reports in [Sentry](https://sentry.io/organizations/resolve-to-save-lives/issues/?project=1217715) to find and fix the problem.
- Notifications are going out for all active experiments
  - Some times, you'll see that current patients notifications are going out but stale patients notifications haven't been for a while
- Message delivery failure rates
  - If the ratio of failed to delivered notifications is abnormally high, you should check with the sms provider.

### Notifications go out after experiment has "ended"
Depending on the cadence of the experiment, notifications may go out for a few days after the experiment's end_time. Like we saw earlier under [experiments](#experiment), end_time is simply the date on which enrollment ends. When messages are configured to go out in a cascade, each patient is enrolled on the earliest remind_on day. When this happens, future notifications will go out at most maximum remind_on days after enrollment. So while enrollment ends on the end_time date, notifications will go out for the next maximum remind_on days.

eg: An experiment's start_time is Feb 1, end_time is Feb 28 and the reminder templates are configured to send notifications on -1 and 3 (remind_on) days from the appointment. On Feb 28, a patient with an appointment on Mar 1 is enrolled so they can be notified on Feb 28, ie -1 days from appointment. They don't visit their appointment on Mar 1. We send them another notification on Mar 4, 3 days after the appointment, reminding them to come for their appointment. So even though the experiment "ended" on Feb 28, it continued to send notifications until Mar 4.

Also see: the [experiment timeline](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/019-ab-testing-enhancements.md#experiment-timeline) diagram.

Also see: [monitoring buffer](#monitoring-buffer) of an experiment

### Monitoring buffer
Visits are monitored and patients are evicted until 15 days (`MONITORING_BUFFER`) from the last enrollment date. This is because we consider notifications to have an influence on the patient for upto 15 days from when the notification was sent.

### Experiment monitoring
The daily experiment runner cron job also monitors an experiment. What does this mean? 

Monitoring includes:
- Recording the statuses of notifications
- Marking visits for patients who returned to care
- Evicting patients who have invalid data 

Reasons for eviction:
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

## Appendix
TODO: Update

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
