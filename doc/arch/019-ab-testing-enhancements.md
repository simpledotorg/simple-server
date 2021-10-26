# A/B Testing Framework enhancements

## Context
Our first attempt at [A/B testing notifications](./017-ab-testing.md) surfaced some concerns:
- The patient selection mechanism selected patients across multiple treatment groups, and patients were excluded
  incorrectly due to past experiments.
- We also found inconsistencies in how notifications were dispatched, which resulted in some patients only
  receiving a subset of the message cascade.
- There are also known issues with how appointments are being recorded in the mobile app which affects how visits are counted.

These inconsistencies make reporting on the results complicated and also reduce the quality of data we get from the experiment. 
Since the validity of the experiment is impacted by this, the issues need to be addressed before we rerun the first 
experiment and run subsequent experiments.

## Decision

[Relevant PRD](https://docs.google.com/document/d/1WushMGEvKzRarGbYerWqUISevjKONPHXwpBgR8y7dOE/edit#)

### Patient Selection
- Enforce treatment group membership constraints. Patients shouldn't have multiple treatment group memberships in active experiments.
- Patients who have multiple scheduled appointments will not be included in the experiment.
- All experiments (including existing finished ones) will have start and end dates - we accidentally excluded a large number of patients from the experiments by not enforcing this constraint.
- Select patients close to their expected visit date. Selecting patients too far in advance increases the likelihood of the patient's state changing before their expected visit.

### Patient eviction
- Patients may need to be evicted from the experiment as the experiment progresses. Evicting a patient from the experiment means that they will not be sent any pending messages, and will be excluded from the results. We will evict patients:
    - who had a new appointment created or their original appointment updated without a corresponding visit (i.e, no bp, blood sugar, or prescription drug was recorded)
    - where we failed to send a notification – this could happen if we have a invalid number or due to network failures.

### Appointment
- We will not infer visits from the creation of appointments. We will rely on Blood Pressures, Blood Sugars and Prescription Drugs only. 
  We also won’t make any changes to the existing dashboards/reports that infer visits using appointments.
  
  **Rationale**: A portion of our appointment records are created due to bugs and problematic UI flows.
  This makes it impossible to distinguish real visits from accidentally created appointments.
  
  **Consequences**: Excluding appointment creation from our criteria will mean that our experiment patients’ total visits will be ~10% lower than the numbers we report on the dashboard. 
  This shouldn’t affect the validity of our results since this ~10% reduction will be distributed uniformly across the treatment groups. Since this may lead to us undercounting visits, we will need to report relative improvements in return rates rather than absolute percentages. For example, if cascade group patients have a 20% return rate and control group patients have a 15% return rate, we should look at the difference here, which is 5% and not the absolute percentages.

- A nurse can update a patient’s appointment from the app and change it’s status or scheduled date.
  In this case the patient’s expected return date becomes unclear because the appointment they were enrolled in the experiment for is no longer relevant.
  This can also happen if an accidental appointment with a different scheduled date was created. 

  When a patient has an appointment updated/created on a day without a visit, we will evict them from the experiment. 
  This is to avoid tracking their new expected visit date and moving their notifications to the correct date, which will introduce noise in the results.

### Tracking visits
- The start date for monitoring return visits for each patient should be the date of enrollment in an experiment (and treatment group).
- The end date for monitoring return visits for each patient should be 14 days from their appointment’s scheduled date.

### Reporting
We will store the results of the experiment in a denormalized format that is close to our final reporting needs.
The reporting schema will be tied to a treatment group membership.
We will populate it everyday by scanning the previous day’s activity.
Any new metrics that we want to track will need to be added to this table.
<Expand on writing to the membership table over separate transactional and reporting>

### Experiment timeline

We currently capture an experiment's timeline by storing a `state` field. The `state` can be
`upcoming`, `running` and `completed`. There are more cadences to the experiment though, which aren't captured
well by this attribute alone. For example
- Notifications are sent out until 3 days after enrollment ends.
- Patients need to be monitored till 14 days after enrollment ends.

The cadences when put on a timeline look like:

![ab-experiment-timeline](https://github.com/simpledotorg/simple-server/raw/5a4008a79e1cffd635b2ce2348ec1b9dea5318e9/doc/arch/resources/ab_experiment_timeline.png)

Additionally, the `state` attribute needs to be kept track of every day and modified when the state changes.
The `start_date` and `end_date` already have all the
information required to figure out the cadences. We will remove the `state` field and introduce methods that work with 
`start_date` and `end_date` to figure out each cadence.

### Separating experiment responsibilities

Running the a/b experiment has the following concerns
- Bucketing
- Sending out notifications
- Data collection
- Reporting

The [experiment flow](https://docs.google.com/document/d/1IMXu_ca9xKU8Xox_3v403ZdvNGQzczLWljy7LQ6RQ6A/edit#) captures 
sub-parts of each of these.

Currently these responsibilities are shared by `Experimentation::Experiment` and `Experimentation::Runner`.
We will pull these apart and have classes set up like so:

- `Experimentation::Experiment` - Setup experiments and assign treatment groups integrally.
- `Experimentation::TreatmentGroup` - Describes a treatment group and the behaviour for the patients in it. 
- `Experimentation::TreatmentGroupMembership` - Stores the patients membership in a treatment group and collects related data.
- `Experimentation::ReminderTemplate` - Specifies what messages need to be sent to which treatment group and when.
- `Experimentation::NotificationsExperiment` - Specifies the default eligibility criteria and conducts a notifications experiment.
- `Experimentation::CurrentPatientExperiment` - Specifies the eligibility criteria for selection and conducts a current patient experiment.
- `Experimentation::StalePatientExperiment` - Specifies the eligibility criteria for selection and conducts a stale patient experiment.

The need to split experiment code into `Experiment` and `NotificationsExperiment` arises from the amount of responsibility 
that comes with maintaining an experiment's integrity. Decoupling the experiment's integrity from the  
day-to-day operations lets us deal with one piece at a time.

The individual experiments will be subclassed from `NotificationsExperiment` since they have enough shared behaviour but are 
distinct when it comes to selection and notifying.

## Status
Being discussed

## Consequences
