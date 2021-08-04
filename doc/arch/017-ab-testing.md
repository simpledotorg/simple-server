# A/B Appointment Reminder Testing

## Context

Our primary goal at Simple is to reduce deaths from cardiovascular disease. To be able to do that, we need patients to return to the clinic for care. Currently, when a patient misses their follow-up appointment date by three days, we send them a polite text message reminding them to continue taking their medicine and to return to their clinic to get more. That is our last attempt via text to convince a patient to return. We would like to know if a different message or sending the message on a different date relative to their appointment date would result in a higher rate of patient return. We would also like patients who have recently stopped visiting their clinic to return to care, and we would like to know what type of message and frequency of message would be most effective for convincing these patients to return to care.

## Decision

We will develop a framework for testing different messages, message delivery dates, and message delivery cadences.

That framework will be able to run experiments for both patients who have upcoming appointments as well as patients who do not because they have not visited their clinic recently.

Patients who have appointments scheduled during the experiment date range will be referred to here as as "current patients".

Patients who last visited the clinic 35-365 days ago will be referred to here as "stale patients". We chose 35 days because most patients are expected to return to clinic monthly so a patient who hasn't been into clinic in over 35 days is probably late, and we chose 365 days as a cutoff because patients who haven't been to clinic in over a year are considered lost to follow up.

Those two types of experiments will require process differences. When the patient has an upcoming appointment, the reminders must be sent relative to the appointment date. Messages can be sent before, on, or after the appointment date.

Messaging for stale patients will run on a continual daily basis during the experiment. This is to stagger the messages over course of the experiment so as to not overwhelm clinics with many patients coming to a clinic on the same day.  We will add a specified number of random stale patients per day to the experiment and schedule them based on the messaging templates configured in the experiment.

In both types of experiments, patients will be randomly placed into treatment groups. Treatment groups will define the message texts, number of messages, and when to send the messages. Patients in an experiment will not receive the standard missed visit reminder that is sent three days after a scheduled appointment. Control group patients will receive no messages at all.

## Patient Selection Criteria

All patients are potentially eligible filtered by the following criteria:

- at least 18 years old
- hypertensive
- has a valid phone number
- is not in an ongoing experiment or one that ended recently

Subjects for current patient experiments will be selected for having an appointment scheduled during the experiment date range.

Subjects for stale patient experiments will be selected for having last visited the clinic 35-365 days ago. We also filter out any patients who have an appointment scheduled in the future. This prevents messaging patients needlessly and also ensures that our experiment patient pools are mutually exclusive.

Patients who have been in an experiment that ended within the past two weeks will be filtered out of the selection process.

## Treatment Group Assignment

Patients will be assigned to treatment groups completely at random during the patient selection process. The patient's treatment group assignment will be captured via the TreatmentGroupMembership model.

## Data modelling

The A/B framework introduces five new models.

- Experiment: This defines the type (i.e., current or stale) and date range of the experiment.
- TreatmentGroup: Treatment groups are used to determine which messages a patient will receive and when they will receive them, but they do not contain any information about the messages. Treatment groups can have zero or more reminder templates, which contain the message information. This design is intended to be flexible enough to allow us to test with any number of messages and allows us to test the same type of messages with different delivery cadences.
- ReminderTemplate: A reminder template captures the message we want to send and when (relative to appointment date) we want to send it. A zero value means to send the message on the appointment date, a negative value means to send the message before the appointment, and positive value means to send the message after the appointment date.
- Notification: this represents a message that is either scheduled to be sent or has already been sent. It will contain the scheduled delivery date and the experiment message (as a locale identifier that will be translated into the [patient's language](#supported-languages)). The Notification model will also be used moving forward to capture our non-experiment appointment notifications. Notifications can have multiple Communications, which represent an attempt to send a notification to a patient via our integration partners (such as Twilio). A communication will be created when the message is successfully received by the integration partner. Whether that message was successfully delivered to the patient is captured in the communication's detailable model.
- TreatmentGroupMembership: this is a join table between TreatmentGroup and Patient that allows us to track which patients were in each treatment group.

## Supported languages

Messages will be localized for the patient based on the state of their assigned facility. We will use the facility address instead of the patient's address because it's more likely to be valid. The language mapping logic can be found in `app/models/facility.rb`.

Experiment messages have been translated into many regional languages in the countries Simple operates in.

## Notification window

We want to ensure that we only send notifications during appropriate hours, so all notifications are scheduled to be sent during the next messaging window (see `Communication.next_messaging_time`). We initially send messages through WhatsApp or Imo, then fall back to SMS. If the callback from WhatsApp/Imo tells us the message failed, we schedule the message to resend either immediately or during the messaging window tomorrow.

## Consequences

We found a bug in which failed missed visit reminders were being resent every day. The bug was fixed, but we did not change the historical data, so there are some appointments that have thousands of failed notifications.

We realized that our notification language localization strategy was very limited and most patient's were receiving notifications in English. This was changed to the strategy described in [patient's language](#supported-languages).

We partially tested the A/B framework by sending medication reminders to patients in India during a Covid lockdown. In that process, we learned of the below Twilio rate limits. We purchased additional phone numbers to speed up the sending process and avoid errors due to the per-second rate limit. These rate limits will need to be considered during any notification-based experiment and additional sending numbers may have to be purchased, to avoid the 2 SMSs/second limit.

- Twilio: We cannot queue more than ~25,000 messages at a time
- Twilio: We cannot send more than 2 SMSs per second per sending phone number. This is 7200 SMSs per hour.
- Whatsapp: We cannot send more than 10,000 messages per day because we are in their Tier 2. We can graduate to the next tier by ensuring our quality rating is adequate and that the cumulative number of users we send notifications to adds up to twice the current messaging limit within a 7-day period (i.e. 20k users). We do not have access to the quality rating because it's only available through the facebook interface, not the twilio interface that we use, but it's clear that we must increase our number of notifications over time if we want to increase the number of whatsapp messages we can send per day without buying more numbers. As our notification volume increases as a result of experiments, we should naturally graduate to the next tier.
- Whatsapp: We can send 25 messages a second

While debugging the covid notifications, we found that our daily notifications window on production was was only one hour per day. As a result, when whatsapp messages failed, the sms retry was often not sent the same day. We expanded the delivery window and moved it from the afternoon to the morning because most clinics close early in the afternoon and we don't want to direct patient's to closed clinics.

Areas of concern include the additional strain on our background queue and the difficulty of debugging background jobs. We have limited visibility into the health of our notifications system. We added extensive logging, datadog dashboards, and a metabase dashboard to mitigate these limitations.

Developers will be responsible for scheduling and monitoring. See `doc/wiki/running-ab-experiments.md`
