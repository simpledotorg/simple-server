# Running SMS reminder experiments

## Prerequisites
To start an SMS experiment you'll need to gather the following information:

- A `name` for the experiment.
- The `type` of experiment - it can target either "Current" patients or "Stale" patients.
- The number of `max_patients_per_day` that will be enrolled per day.
- `start_time` - enrollments will begin at this time.
- `end_time` - enrollments will stop at this time .
- `treatment_groups` - Each treatment group will have a different content or frequency of messages sent to it.
    - You will probably also need a `control` group as a baseline in addition to all the groups that will receive messages.
- The content and frequency of messages in each treatment group. This will be captured in the
  `reminder_templates` of each group.
  For current patients, the `remind_on` of reminder templates is set relative to the date
  they are expected to return. For stale patients, it's the date of enrollment.
- If the experiment has new messages and translations you'll need to get them [approved by DLT](doc/howto/bsnl/sms_reminders.md) and make sure they're present in
  [config](../config/data/bsnl_templates.yml).

## Setup
- Enable the `experiment` and `notifications` flipper flags.
- Create a data migration in the style of [this data migration](db/data/20220412130957_create_apr2022_ihci_experiment.rb).
It should setup the `experiment`, its `treatment_groups` and `reminder_templates`.
- Put a guard clause to make sure the migration runs only in the env you want. Write a spec for the migration.

**Note about consecutive experiments**

An experiment that sends notifications in advance enrolls patients who have appointments in the future.
For an experiment starting right after, this can mean that all the patients might've already been enrolled
in the first one. Make sure there's at least a gap of these many days (only if this value is positive) to avoid this
```ruby
 experiment_1 = Experimentation::Experiment.find("<old experiment's id>")
 experiment_2 = Experimentation::Experiment.find("<new experiment's id>")
 experiment_1.earliest_remind_on - experiment_2.earliest_remind_on
```

## Running the experiment

A cron in `schedule.rb` orchestrates the experiment. It runs a set of tasks everyday.
When an experiment starts, you should
- Check in on the metabase dashboards every once in a while.
- We get a daily summary on slack on #ab-testing-stats. Check on the "Pending notifications" report everyday. 
  This number should always be 0. If not, this points to an issue in the system. 
  Make sure to dig in what's up by looking at sentry logs.
- Run `rake:get_account_balance` every once in a while, check the balance and recharge if needed. 


Notes:
- Depending on the cadence, notifications may go out for a few days after the experiment has "ended".
- Visits are monitored and patients are evicted until 15 days (`MONITORING_BUFFER`) from the last enrollment date.

### Important links

- [IHCI metabase dashboard](https://metabase.simple.org/dashboard/54-notifications-experiment-generic-dashboard)
- [Bangladesh metabase dashboard](https://metabase.bd.simple.org/dashboard/10-notifications-experiment-generic-dashboard)
- [IHCI CSV export](https://metabase.simple.org/question/496-a-b-experiments-statistical-analysis-report)
- [Bangladesh CSV export](https://metabase.bd.simple.org/question/132-a-b-experiments-nhf-statistical-analysis-report)

If you're adding any new reports to the IHCI dashboard save them in this [collection](https://metabase.simple.org/collection/43-a-b-testing-ihci-shared)
so it's viewable by other people.

### Cancelling an experiment
 
```ruby
Experimentation::NotificationsExperiment.find("<experiment id>").cancel
```

## In the long run

- When we decide on a message format and start sending a single message eventually, the current plan
  is to run an "experiment" with a single bucket. Although, a patient can be enrolled in an experiment only once.
  A single long running experiment will hence not work for patients who need to follow up every month.
  A new experiment will need to be started every month.
- The `treatment_group_memberships` and `notifications` tables are fast growing. 
  We will have to think about [archiving them frequently](https://app.shortcut.com/simpledotorg/story/7931/data-archival-strategy-for-notification-communication-and-delivery-detail-records)
  once we start doing regular notifications.


