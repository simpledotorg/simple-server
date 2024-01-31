# Experiments Wiki

Entrypoint to knowing everything about experiments in Simple.

## Overview

We conduct A/B testing through the experiments model. Since the reason to set this up was specifically to run A/B experiments on different notification strategies (see [context for setting up A/B testing](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/017-ab-testing.md#context)), currently experiments are somewhat coupled to notification experiments. This is useful to know going into the code.

- Information about the data modeling can be found [here](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/017-ab-testing.md#data-modelling)
- Information about the object design can be found [here](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/019-ab-testing-enhancements.md#object-design-and-separation-of-concerns)

### Current and stale patients

Patients who have appointments scheduled during the experiment date range are "current patients". These patients are under care and we simply wish to convince them to return to the clinics for continued care.

Patients who last visited the clinic 35-365 days ago are refered to as "stale patients". We chose 35 days because most patients are expected to return to clinic monthly so a patient who hasn't been into clinic in over 35 days is probably late, and we chose 365 days as a cutoff because patients who haven't been to clinic in over a year are considered lost to follow up.

Patients who have an appointment scheduled in the future are filtered out from stale patient experiments because some patients have appointments scheduled once in 2 months or even less frequently. This also ensures that our experiment patient pools are mutually exclusive.

## Experiment lifecycle

Each day enrollment, monitoring, notification scheduling

## Notifications

## Setting up and running an experiment

A how-to guide to set up an experiment can be found [here](https://github.com/simpledotorg/simple-server/blob/050ed4c4270768feb3243c7489ef29e81115b756/doc/howto/sms_reminder_experiments.md).

To simply set up sms reminders without experimenting, see [here](https://github.com/simpledotorg/simple-server/blob/050ed4c4270768feb3243c7489ef29e81115b756/doc/howto/sms_reminders.md). 

## FAQs

This section deals with theoretical/generic FAQs about experiments. More operational FAQs relating to running an experiment can be found [here](https://github.com/simpledotorg/simple-server/blob/050ed4c4270768feb3243c7489ef29e81115b756/doc/howto/sms_reminders.md).

### Where is the reporting information stored

Reporting information on each enrollment is marked under their treatment group membership row. 

### Why evicted patients continue to be part of the experiment

If a patient visits after they have been evicted from the experiment, their visit is still recorded. This means that even though a patient has been evicted, they continue to be part of the experiment flow. Why do we do this?  

We want to capture the maximum data about an experiment. If we record both eviction and visit data, we can choose to include/exclude patients when making the final report.

In the past, we have used this data in experiment reports, for example to make a `Treatment as intended` and `Treatment as received` analysis where:
- as intended – We sent an SMS and they visited
- as received – They actually got an SMS and they visited

### Why we don't infer visits from appointment creation

See [tracking visits and the rationale](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/019-ab-testing-enhancements.md#tracking-visits)

### Enrollment of patients in consecutive experiments

## Known gotchas

### Why stale patient notifications don’t go out for the first week

Stale patient eligiblity is calculated on the 


