# How to run the initial AB Experiment in India Production

### Date: July 2021
### References
* [clubhouse story ch3586](https://app.clubhouse.io/simpledotorg/story/3586/test-in-sandbox)
* [GitHub PR](https://github.com/simpledotorg/simple-server/pull/2752)

---


*Note: these instructions are only valid for Tuesday July 27 before 4pm IST (the end of the messaging window).*

1. Turn on `experiment` and `whatsapp_appointment_reminders` Flipper feature flags
2. Merge https://github.com/simpledotorg/simple-server/pull/2752 - it includes a migration that will create two new experiments with three treatment groups each. To verify:

```ruby
experiments = Experimentation::Experiment.where(name: "Small Current Patient July 2021")
experiments.count # should return 1
experiments.map { |e| e.treatment_groups.count } # should return 3
```

3. Create the current patient experiment, based on how many patients are eligible. We want to use approximately 300 patients and this particular job uses percentages. So if 10,000 patients are eligible, we would want to use 3% (300/10,000).
**NOTE:** change the percentage below so that the experiment enrolls ~300 patients

```ruby
Time.zone = Period::REPORTING_TIME_ZONE

candidates = Experimentation::Runner.current_patient_candidates("July 28, 2021".to_date, "July 30, 2021".to_date).count
# => 10000 ...assume there are 10,000 eligible patients returned...
percentage = 300 / candidates.to_f * 100 # results in 3
Experimentation::Runner.start_current_patient_experiment(name: "Small Current Patient July 2021", days_til_start: 1, days_til_end: 3, percentage_of_patients: percentage)

# Verification
experiment = Experiment.find_by!(name: "Small Current Patient July 2021")
experiment.notifications.count
# => should return around 400 notifications
```

4. Launch the job to schedule the first wave of notifications from a rails console.
The changes may not be immediate due to the nature of background jobs, but this should result in the notifications that are due today being changed to status "sent". It should also create communications for those notifications.

```ruby
AppointmentNotification::ScheduleExperimentReminders.perform_now
# Run the following after the job has finished running (check Sidekiq web UI)
ns = Notification.where(remind_on: Date.current)
ns.pluck(:status).uniq  # (should all equal "sent")
ns.map {|n| n.communications.count}.uniq # (expect 1 and maybe 2; may still include 0 due to twilio errors)
```

### Troubleshooting

* Monitor Sentry and Datadog logs for any errors or anomalies while running
* Check the Twilio logs to ensure SMS / Whatsapp messages are really being sent
* If you need to cancel an experiment for any reason, run the following from a rails console:

```ruby
Experimentation::Runner.abort_experiment(name)
```


