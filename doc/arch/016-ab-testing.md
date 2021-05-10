# A/B Appointment Reminder Testing

## Context

Our primary goal at Simple is to reduce deaths from cardiovascular disease. To be able to do that, we need patients to return to the clinic for care. Currently, when a patient misses their follow-up appointment date by three days, we send them a polite text message through Whatsapp (in India) and SMS reminding them to continue taking their medicine and to return to their clinic to get more. That is our last attempt via text to convince a patient to return.

We would like to know if a different message or sending the message at a different time relative to their appointment date would result in a higher rate of patient return.

Additionally, we would like patients who have recently stopped visiting their clinic to return to care, and we would like to know what type of message and frequency of message would be most effective for convincing these patients to return to care.

## Decision

We will develop a framework for testing different messages, message delivery dates, and message delivery cadences.

That framework will be able to run experiments for both patients who have upcoming appointments as well as patients who do not because they have not visited their clinic recently.

Patients who have upcoming appointments will be referred to here as as "active patients".

Patients who last visited the clinic 35-365 days ago will be referred to here as "stale patients". We chose 35 days because most patients are expected to return to clinic monthly so a patient who hasn't been into clinic in over 35 days is probably late, and we chose 365 days as a cutoff because patients who haven't been to clinic in over a year are considered lost to follow up.

Those two types of experiments will require small process differences. When the patient has an upcoming appointment, the reminders must be sent relative to the appointment date.

That doesn't make sense for patients who do not have upcoming appointments, so their reminders can be sent at any time. There are many patients who fall into this category, and we don't want to risk driving too many patients back to care at once and overwhelming clinics. To mitigate that possibility, we will add 10,000 patients per day to the experiment and schedule their reminders to be sent starting the same day. Because patients can receive no reminders, a single reminder, or a series of reminders, the actual number of reminders sent per day may exceed 10,000.

In both types of experiments, patients will be randomly placed into treatment groups. Treatment groups will define the message texts, number of messages, and when to send the messages. Test patients will not receive the pre-existing text message sent three days after they miss an appointment.

## Patient Selection Criteria

Simple servers are hosted per country and the selection pool will incude all patients on the server, so it will include all patients in the experiment country.

All patients must meet the following criteria for selection:
- at least 18 years old
- hypertensive
- has a phone capable of receiving text messages. We verify this via Exotel.
- have not taken part in an experiment in the past 14 days. This will not matter for the first experiment but will for subsequent experiments.

Subjects for active patient experiments will be selected for having an appointment scheduled during the experiment date range.

Subjects for stale patient experiments will be selected for having last visited the clinic 35-365 days ago. To ensure that the two experiment subject groups are entirely mutually exclusive, we also filter out any patients who have an appointment scheduled during the experiment.

## Treatment Group Assignment

Patients will be assigned to treatment groups completely at random using a simple Ruby randomization technique during the patient selection process. The patient's treatment group assignment will be captured via the TreatmentGroupMembership model.
## Test workflow

Active patient experiment:
- experiment will be started by running a script either manually or by scheduling it
- that script will select patients appropriate to the experiment
- it will then assign all eligible patients to treatment groups at random
- it will create all appointment reminders for experiment patients, based on the date of their next appointment and the information in their treatment group's reminder templates. These will be marked as "pending" and will not be sent at this time.
- a cron job will run every day and search for any pending appointment reminders that should be sent that day
- that cron will schedule individual text messages to be sent out that day
- in India, text messages will first be sent as WhatsApp messages. If the WhatsApp message fails, we will resend the message as SMS.
- in Bangladesh, text messages will first be sent as Imo messages. If the Imo message fails, we will resend the message as SMS.

Stale patient experiment:
- experiment must be scheduled by cron because the selection process is not a one-time occurrence
- patient selection must occur every day of the experiment to ensure that patients do not become ineligible (by returning to care) between selection and the time their reminder is sent.
- the scheduled script selects 10,000 patients per day to send reminders to, assigns them to a treatment group, and creates appointment reminders appropriate for that group
- patients in the control group will receive no reminders while other groups may receive multiple reminders over a period of days

## Data modelling

The A/B framework introduces five new models.

- Experiment: This defines the type (active or stale) and date range of the experiment.
- TreatmentGroup: Treatment groups are used to determine which messages a patient will receive and when they will receive them, but they do not contain any information about the messages. Treatment groups can have zero or more reminder templates, which contain the message information. This design is intended to be flexible enough to allow us to test with any number of messages and even allows us to test the same type of messages with different delivery cadences.
- Reminder template: A reminder template captures the message we want to send and when (relative to appointment date) we want to send it. A zero value means to send the message on the appointment date, a negative value means to send the message before the appointment, and positive value means to send the message after the appointment date.
- AppointmentReminder: this represents a message that is either scheduled to be sent or has already been sent. It will capture the message and scheduled delivery date. This will also be used moving forward to capture our non-experiment appointment notifications.
- TreatmentGroupMembership: this is a join table between TreatmentGroup and Patient that allows us to track which patients were in each treatment group.

## Supported languages

Messages will be localized for the patient based on the state of their assigned facility. We will use the facility address instead of the patient's address because it's more likely to be valid.

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

## Consequences

Some issues with existing code were discovered and corrected in the development process, but this feature should have no impact on existing functionality. We will be using the appointment reminder model to provide a historical record of sent appointment notifications moving forward, but that will not impact the user experience.

## Ending an experiment early

The rake tasks will be guarded by a feature flag, which will allow us to quickly prevent all experiment messages from being sent. We will also write a script for changing the experiment state to "complete" and marking all appointment reminders as "cancelled".