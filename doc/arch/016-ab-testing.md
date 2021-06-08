# A/B Appointment Reminder Testing

## Context

Our primary goal at Simple is to reduce deaths from cardiovascular disease. To be able to do that, we need patients to return to the clinic for care. Currently, when a patient misses their follow-up appointment date by three days, we send them a polite text message reminding them to continue taking their medicine and to return to their clinic to get more. That is our last attempt via text to convince a patient to return. We would like to know if a different message or sending the message on a different date relative to their appointment date would result in a higher rate of patient return. We would also like patients who have recently stopped visiting their clinic to return to care, and we would like to know what type of message and frequency of message would be most effective for convincing these patients to return to care.

## Decision

We will develop a framework for testing different messages, message delivery dates, and message delivery cadences.

That framework will be able to run experiments for both patients who have upcoming appointments as well as patients who do not because they have not visited their clinic recently.

Patients who have appointments scheduled during the experiment date range will be referred to here as as "active patients".

Patients who last visited the clinic 35-365 days ago will be referred to here as "stale patients". We chose 35 days because most patients are expected to return to clinic monthly so a patient who hasn't been into clinic in over 35 days is probably late, and we chose 365 days as a cutoff because patients who haven't been to clinic in over a year are considered lost to follow up.

Those two types of experiments will require process differences. When the patient has an upcoming appointment, the reminders must be sent relative to the appointment date. Messages can be sent before, on, or after the appointment date.

That doesn't make sense for patients who do not have upcoming appointments. Messages for stale patients will start on the same day the patient is added to the experiment. There are many patients who fall into this category, and we don't want to risk driving too many patients back to care at once and overwhelming clinics. To mitigate that possibility, we will add 10,000 patients per day to the experiment and schedule their reminders to be sent starting on the day they were added to the experiment. Because patients can receive no reminders, a single reminder, or a series of reminders, the actual number of reminders sent on any given day may exceed 10,000.

In both types of experiments, patients will be randomly placed into treatment groups. Treatment groups will define the message texts, number of messages, and when to send the messages. Test patients will not receive the pre-existing text message sent three days after they miss an appointment. Control group patients will receive no messages at all.

## Patient Selection Criteria

Simple servers are hosted by country and the selection pool will incude all patients on the server, so all patients in the experiment country will be potentially eligible.

All patients must meet the following criteria for inclusion:
- at least 18 years old
- hypertensive
- has a phone capable of receiving text messages. We verify this via Exotel.
- is not in an ongoing experiment or one that ended within the past 14 days.

Subjects for active patient experiments will be selected for having an appointment scheduled during the experiment date range.

Subjects for stale patient experiments will be selected for having last visited the clinic 35-365 days ago. We also filter out any patients who have an appointment scheduled in the future. This prevents messaging patients needlessly and also ensures that our experiment patient pools are mutually exclusive.

Patients who have been in an experiment that ended within the past two weeks will be filtered out of the selection process.

## Treatment Group Assignment

Patients will be assigned to treatment groups completely at random during the patient selection process. The patient's treatment group assignment will be captured via the TreatmentGroupMembership model.

## Experiment workflow

### Experiment setup:
- experiments can be set up by adding a data migration to `db/data`
- an example of how to set up an experiment can be found in `lib/seed/experiment_seeder.rb`

### Active patient experiment:
- experiment will be started by running a script either manually or by scheduling it
- the job can be run like so: `ExperimentControlServerice.start_current_patient_experiment(name, days_til_start, days_til_end, percentage_of_patients = 100)`
- the `percentage_of_patients` argument is optional and defaults to 100
- be sure that `days_til_start` leaves enough time to send any reminders that need to be sent before the appointment. For example, if the experiment has a treatment that involves sending reminders three days before the experiment begins, set `days_til_start` to at least four.
- the job will select patients according to the [selection criteria](#patient-selection-criteria)
- it will then assign all eligible patients to treatment groups at random
- it will create all notifications for experiment patients, based on the date of their next appointment and the information in their treatment group's reminder templates. These will be marked as "pending" and will not be sent at this time.
- Then the messages will need to be [scheduled for delivery](#notification-scheduling)

### Stale patient experiment:
- stale patient selection is run via the command: `ExperimentControlService.schedule_daily_stale_patient_notifications(name, patients_per_day: PATIENTS_PER_DAY)`
- the `patients_per_day` argument is optional and defaults to 10,000
- this job should be scheduled because patient selection must occur every day of the experiment to ensure that patients do not become ineligible (by returning to care) between selection and the time their reminder is sent
- this job selects the specified number of patients per day to send reminders to according to the [selection criteria](#patient-selection-criteria), assigns them to treatment groups, and creates notifications appropriate for their group. These notifications will be marked as "pending" and will not be sent at this time.
- patients in the control group will receive no reminders while other groups may receive multiple reminders over a period of days
- Then the messages will need to be [scheduled for delivery](#notification-scheduling).

### Notification scheduling
- notifications are scheduled to be sent daily via a job that will need to be run every day during the experiment before the [notification window](#notification-window)
  - the job can be run via the command: `AppointmentNotification::ScheduleExperimentReminders.perform`
  - because this job must be run daily, it should be scheduled via `config/schedule.rb`
- it will search for any pending notifications with a `remind_on` of today, mark the notification as "scheduled", and schedule a sidekiq worker to send the notification during the [notification window](#notification-window)
- in India, text messages will first be sent as WhatsApp messages. If the WhatsApp message fails, we will resend the message as SMS.
- in Bangladesh, text messages will first be sent as Imo messages. If the Imo message fails, we will resend the message as SMS.

### Experiment cleanup:
- after an experiment is over, its state should be changed to "complete"
  - stale patient experimeents are automatically changed to "complete" when the experiment end date has passed.
  - active patient experiments must be manually changed to "complete". Failure to change the experiment to complete will prevent us from starting another active patient experiment but has no other negative side effects.
- it's important to note that notifications can be scheduled beyond the experiment end date due to the cascading nature of notifications. The end date is used by the selection process and not to prevent notifications from being sent.
- to prevent notifications from being sent, the experiment must be marked "cancelled", not "complete". Experiments can be ended early via a [script](#ending-an-experiment-early).

## Data modelling

The A/B framework introduces five new models.

- Experiment: This defines the type (i.e., active or stale) and date range of the experiment.
- TreatmentGroup: Treatment groups are used to determine which messages a patient will receive and when they will receive them, but they do not contain any information about the messages. Treatment groups can have zero or more reminder templates, which contain the message information. This design is intended to be flexible enough to allow us to test with any number of messages and allows us to test the same type of messages with different delivery cadences.
- ReminderTemplate: A reminder template captures the message we want to send and when (relative to appointment date) we want to send it. A zero value means to send the message on the appointment date, a negative value means to send the message before the appointment, and positive value means to send the message after the appointment date.
- Notification: this represents a message that is either scheduled to be sent or has already been sent. It will contain the message as a locale identifier that will be translated into the [patient's language](#supported-languages) and scheduled delivery date. The Notification model will also be used moving forward to capture our non-experiment appointment notifications.
- TreatmentGroupMembership: this is a join table between TreatmentGroup and Patient that allows us to track which patients were in each treatment group.

## Supported languages

Messages will be localized for the patient based on the state of their assigned facility. We will use the facility address instead of the patient's address because it's more likely to be valid. The language mapping logic can be found in `app/models/facility.rb`.

Experiment messages have been translated into the following languages:

Bangladesh:
Bangla

Ethiopia:
Amharic
Oromo
Somali
Tigrinya

India:
Bengali
Hindi
Kannada
Marathi
Punjabi
Tamil
Telugu

## Notification window

We want to ensure that we only send notifications during appropriate hours, so all notifications are scheduled to be sent during the next messaging window (see `Communication.next_messaging_time`). We initially send messages through WhatsApp or Imo, then fall back to SMS. If the callback from WhatsApp/Imo tells us the message failed, we schedule the message to resend either immediately or during the messaging window tomorrow.

Because these experiments will dramatically increase the number of notifications being sent daily, we are expanding the notifications window. Currently, the window is from 10am-4pm IST. Later experiments will likely test sending messages at different times of day.

## Consequences

Some issues with existing code were discovered and corrected in the development process, but this feature should have no impact on existing functionality. We will be using the notification model to provide a historical record of sent appointment notifications moving forward, but that will not impact the user experience.

## Ending an experiment early

If we need to end an experiment early, we can do it by running `ExperimentControlService.abort_experiment(experiment_name)`. This will change the experiment state to "cancelled" and marking all "pending" and "scheduled" notifications as "cancelled", which will prevent all unsent notifications from being sent.