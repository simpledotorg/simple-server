This is an overview and howto for the first public launch of AB notifications in India. For more context and related stories and PRs, see the [Clubhouse Story](https://app.clubhouse.io/simpledotorg/story/4318/release-plan-for-first-full-ab-experiment) this plan was taken from.

## Release plan

NOTE: "Launch day" below is the day when the experiments are started and notifications will actually start to send.

### Launch Day (Wednesday)
1. 7:30am IST /  11pm : a Nilenso developer will monitor the current experiment data creation
   1. Query for a breakdown of `active_notifications_per_day` (the query for this will be created in one of the subtasks).
   1. Check metabase
1. 8:30am IST: a Nilenso developer will monitor the stale experiment progress. Some things to monitor:
    * [Datadog metrics dashboard](https://app.datadoghq.com/dashboard/y9g-qt8-2jp/appointment-notifications-monitoring-ihci)
    * [Datadog notifications logs](https://app.datadoghq.com/logs?saved_view=466966) - this filters events to show those where `module=notifications`
    * Twilio dashboard - check error rates versus successful sends
    * Sentry.io
    * Sidekiq queues
    * Verify that we aren't sending duplicate messages to any patients -- i.e. avoid spamming / dupe messages
1. 8:30am IST: a Nilenso developer will monitor the selection process for the stale patient experiment.
1. 10:00am-4pm IST: a Nilenso developer will monitor the datadog dashboard and Sentry while notifications begin to send
1. At EOD, take a screenshot of the dashboard and share it here & in Slack, as it will be helpful context for the success rate of the first day.

### Subsequent days

Continue to monitor the resources above for any anomalies or errors.

## Fail safe

If at any point things are going sideways, the experiment can be turned off by:

1. disabling the `experiments` and `notifications` feature flag
1.`bundle exec rails runner ExperimentControlService.abort_experiment("Current Patient August 2021")`

----
### Pre Launch

_These items are **done**, kept for context here only_

1. 6pm IST / 8:30 ET: Kris and Prabhanshu will meet Monday morning to validate the results of the small experiments
1. 7:00pm IST / 9:30am ET: Kris meets with Prabhanshu & @sanheim
1. 7:00pm IST / 9:30am ET: Make sure feature flag 'experiment' and 'whatsapp_appointment_reminders' are turned on and `notifications` flag is still off @prabhanshu
1. 9:30pm IST / 12:00pm EST: Notify any stakeholders that should be notified ( @dburka would know who this is)
1. 9:30pm IST / 12:00pm EST - change notifications window to 8am-12pm - ch4392
1. 9:30pm IST / 12:00pm EST - merge the subject locale fix + refactoring - ch4398 @sanheim
1. 9:30pm IST / 12:00pm EST: Merge and run data migration that creates the active patient and during the US work day @kpethtel - ch4323
1. 9:30pm IST / 12:00pm EST - make sure the schedule is configured and ready to go for the first day - ch4322

----

## Answered Questions

1. Do we need to rate limit over the course of an experiment to avoid the 10,000 unique recipient WhatsApp limit?
   1. Answer: We've changed the code to user more sender numbers, which was sufficient for the medication reminder experiment, which had similar or higher message volume.
3. We need to get approval for all the submitted WhatsApp messages
   1. Answer: Done
4. Should we pick one or two states to start with to limit the amount of notifications we are trying tos edn w/ the first experiment?
   1. Answer: no one has requested it, so no.

## Messaging Rate Limits

* https://support.twilio.com/hc/en-us/articles/115002943027-Understanding-Twilio-Rate-Limits-and-Message-Queues
* https://support.twilio.com/hc/en-us/articles/360024008153-WhatsApp-Rate-Limiting
* https://developers.facebook.com/docs/whatsapp/api/rate-limits