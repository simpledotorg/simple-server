# Experiments Wiki

Entrypoint to knowing everything about experiments in Simple.

## Overview

We conduct A/B testing through the experiments model. Since the reason to set this up was specifically to run A/B experiments on different notification strategies (see [context for setting up A/B testing](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/017-ab-testing.md#context)), currently experiments are somewhat coupled to notification experiments. This is useful to know going into the code.

- Information about the data modeling can be found [here](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/017-ab-testing.md#data-modelling)
- Information about the object design can be found [here](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/019-ab-testing-enhancements.md#object-design-and-separation-of-concerns)

To see all the moving parts of an experiment, one can look at what the experiment runner does to run through an experiment. When we see this, it immediately becomes clear that sending out notifications is as significant and involved as enrolling and monitoring patients everyday.

![experiment-runner](https://github.com/simpledotorg/simple-server/raw/bd6efd9acb697bd90a67137f8abf38aac32aea07/doc/wiki/resources/experiment-runner.png)

### Current and stale patients

Patients who have appointments scheduled during the experiment date range are "current patients". These patients are under care and we simply wish to convince them to return to the clinics for continued care.

Patients who last visited the clinic 35-365 days ago are refered to as "stale patients". We chose 35 days because most patients are expected to return to clinic monthly so a patient who hasn't been into clinic in over 35 days is probably late, and we chose 365 days as a cutoff because patients who haven't been to clinic in over a year are considered lost to follow up.

Patients who have an appointment scheduled in the future are filtered out from stale patient experiments because some patients have appointments scheduled once in 2 months or even less frequently. This also ensures that our experiment patient pools are mutually exclusive.

## Notifications

### Object model

The messaging object model looks like this:

![messaging-object-design](https://github.com/simpledotorg/simple-server/raw/bd6efd9acb697bd90a67137f8abf38aac32aea07/doc/wiki/resources/messaging-object-design.png)

A notification itself represents a message that needs to be delivered to a patient. This message can be delivered in numerous ways; it can even be tried in one way and retried in another.

The different ways a notification can be sent are represented by `communications`. Each communication has a type (eg: sms, VoIP call). Sms communications also belong to a delivery detail.

A detailable or delivery detail is used to store the delivery details of a communication. The details vary wildly across vendors, so detailables abstract out that information. Each vendor's detailable is implemented from the DeliveryDetail abstract class. Each detailable has its own communication.

Messaging channel is an abstraction over the vendor's API.

### Timeline

What happens when a notification is scheduled to be sent? We want two things to happen:
- The notification should be sent via the appropriate messaging channel
- The notification's status should be asynchronously updated whenever it is available

From the [the image](#overview) in the overview section above, we see that the notification dispatch service sends the message on the appropriate messaging channel, i.e. it calls the vendor's API, and marks the notification status as `sent`.

#### So how does the message status get updated?

There are two mechanisms that vendors can provide for us to get the status of a message: push and pull.

For a pull-based mechanism, we run a cron job daily to:
- make API calls to the vendor to receive the the updated status
- update the delivery detail object

The cron job picks up messages that are in any non-terminal state for 2 days, so even if the status hasn't updated in a day, it is checked again the next day. 

This is eventually reflected in the notification status like this:
- communication

![sms-status-update](https://github.com/simpledotorg/simple-server/raw/bd6efd9acb697bd90a67137f8abf38aac32aea07/doc/wiki/resources/sms-status-update.png)

## Setting up and running an experiment

A how-to guide to set up an experiment can be found [here](https://github.com/simpledotorg/simple-server/blob/050ed4c4270768feb3243c7489ef29e81115b756/doc/howto/sms_reminder_experiments.md).

To simply set up sms reminders without experimenting, see [here](https://github.com/simpledotorg/simple-server/blob/050ed4c4270768feb3243c7489ef29e81115b756/doc/howto/sms_reminders.md).

## FAQs

This section deals with theoretical/generic FAQs about experiments. More operational FAQs relating to running an experiment can be found [here](https://github.com/simpledotorg/simple-server/blob/050ed4c4270768feb3243c7489ef29e81115b756/doc/howto/sms_reminders.md).

### Where is the reporting information stored

Reporting information on a patient is stored on their corresponding treatment group membership object.

### Why do we mark visits of evicted patients

We want to capture the maximum data about an experiment. If we record both eviction and visit data, we can choose to include/exclude patients when making the final report.

In the past, we have used this data in experiment reports, for example to make a `Treatment as intended` and `Treatment as received` analysis where:
- as intended – We sent an SMS and they visited
- as received – They actually got an SMS and they visited

### Why don't we infer visits from appointment creation

See [tracking visits and the rationale](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/019-ab-testing-enhancements.md#tracking-visits)

### Enrollment of patients in consecutive experiments

Patients enrolled on the 30th day are available to be enrolled in a new experiment 15 days after. They become available cyclically, so if two experiments run end to end, the full patient pool is eventually available by the 15th day of the second experiment.

### Can experiments overlap

No, only one experiment of a certain type can be active at a time.

## Known gotchas

### Stale patient notifications don’t go out for the first week

To find eligible patients for stale patient experiments, we do a join on the `reporting_patient_visits` materialised view and filter visits by current month. In India, routine matview refreshes occur weekly, so from the beginning of the month until the first matview refresh of the month(upto a week), there are no eligible patients for stale patient experiments. So no notifications go out during that time.  

### Evicted patients continue to be part of the experiment flow

Even after patients are evicted from an experiment, we continue to check if they have visited for the rest of the experiment and mark their visit. An explanation for this can be found [here](#why-we-mark-visits-of-evicted-patients).

