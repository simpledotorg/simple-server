# A/B Appointment Reminder Testing

## Context

Our primary goal with simple is to reduce deaths from cardiovascular disease. To be able to do that, we need patients to return to the clinic for care. Currently, when a patient misses their follow-up appointment date by three days, we send them a polite text message through Whatsapp (in India) and SMS reminding them to continue taking their medicine and to return to their clinic to get more. That is our last attempt via text to convince a patient to return. We would like to know if a different message or sending the message at a different time relative to appointment date would result in a higher rate of patient return.

Additionally, we would like patients who have recently stopped visiting their clinic to return to care, and we would like to know what type of message and frequency of message would be most effective for convincing these patients to return to care.

## Decision

We will develop a framework for testing different messages, message delivery dates, and message delivery cadences.

That framework will be able to run tests for active patients. Active patients are defined as patients who have an appointment scheduled during the test dates. This experiment will select patients who

The framework will also be able to run tests for patients who have recently stopped visiting their clinic. We will sometimes refer to those patients as "stale", defined as patients who last visited a clinic more than 35 days but less than a year ago.

In both types of experiments, patients will be randomly placed into treatment groups. Test patients will not receive the usual text message sent three days after they miss an appointment.

## Patient Selection Criteria

Simple servers are hosted per country and the selection pool will incude all patients on the server, so it will include all patients in the experiment country.

All patients must meet the following criteria for selection:
- at least 18 years old
- hypertensive
- has a phone capable of receiving text messages. We verify this via Exotel.
- have not taken part in an experiment in the past 14 days. This will not matter for the first experiment but will for subsequent experiments.

Active patients will also be selected for having an appointment scheduled during the experiment date range.

Stale patients will be selected for having last visited the clinic in the past 35-365 days. To ensure that the two experiment subject groups are entirely mutually exclusive, we also filter out any patients who have an appointment scheduled during the experiment.

## Treatment Group Assignment (i.e., bucketing)


## Test workflow

Active patient experiment:
- experiment will be started by running a script either manually or by scheduling it
- that script will select patients appropriate to the experiment
- it will then assign eligible patients to treatment groups at random
- it will create all appointment reminders for experiment patients, based on the date of their next appointment and the information in their treatment group's reminder templates. These will be marked as "pending" and will not be sent at this time.
- every day, a cron job will run and look for any pending appointment reminders that are scheduled to be sent on this day
- that cron will schedule individual text messages to be sent out
* this is where we should consider making some small changes
- in India, text messages will first be sent as WhatsApp messages. If the WhatsApp message fails, we will resend the message as SMS.
- in Bangladesh, text messages will first be sent as Imo messages. If the Imo message fails, we will resend the message as SMS.

Stale patient experiment:
- patients must be selected for stale patient experiments every day of the experiment. This is done to ensure that they do not become ineligible (by returning to care) between selection and the time their reminder is sent.
- because of this, stale patient experiments must be scheduledd via cron
- the scheduled script selects 10,000 patients per day to send reminders to, assigns them to a treatment group, and creates appointment reminders appropriate for that group
- patients in the control group will receive no reminders while other groups may receive multiple reminders over a period of days


## Data modelling

The A/B framework introduces five new models.

- Experiment: This defines the type (active or stale) and date range of the experiment.
- TreatmentGroup: Treatment groups are used to determine which messages a patient will receive and when they will receive them, but they do not contain any information about the messages. Treatment groups can have zero or more reminder templates, which contain the message information. This design is intended to be flexible enough to allow us to test with any number of messages and even allows us to test the same type of messages with different delivery cadences.
- Reminder template: A reminder template captures the message we want to send and when (relative to appointment date) we want to send it. A zero value means to send the message on the appointment date, a negative value means to send the message before the appointment, and positive value means to send the message after the appointment date.

- AppointmentReminder: this represents a message that is either scheduled to be sent or has already been sent. It will capture the message and scheduled delivery date. This will also be used moving forward to capture our existing appointment notifications.
- TreatmentGroupMembership: this is a join table between TreatmentGroup and Patient that allows us to track which patients were in each treatment group.

## Supported languages

## Consequences

## Ending an experiment early

