# Repository Layer for Reporting Data

## Context

We generate many reports for the Simple dashboard and the mobile app. Retreving all the data for these reports in a
consistent and performant manner is a challenge.  We need to aggregate and filter a large amount of data across multiple reports, and its important for user confidence that we have the same numbers reported regardless of what report they are on.

Our current reports retrieve their data in a variety of ways:

* Region reports grab from the RegionService, which grabs a large amount of data via the ControlRateService and Result object.
* Cohort reports grab data from the CohortService
* The Progress Tab in the mobile app grabs data from a mix of the ActivityService, ControlRateService, and other legacy objects.

## Decision

We will introduce a [Repository](https://martinfowler.com/eaaCatalog/repository.html) layer that will be responsible for returning reporting data. It will provide a consistent
interface where callers provide one to many Regions, and one to many Periods, and then can retreive whatever values they want from the Repository for the intersection of those Regions and Periods.

The Repository will be responsible for grabbing the values from whatever queries, calculations, or data sources are necessary, and will also handle any rqeuired caching to make sure things are performant.

## Status

Proposed - partially implemented and used for region reports

## Consequences

* Our current reports will need to be migrated over time to this new Repository layer
* We will be storing more fine grained values in our cache (Redis) - this will be a performance win for many reporting needs
where we need just a few metrics across a set of regions / periods.  This will use more memory in our cache though.
* We will need to consider how to construct the queries and calculations that lay below the Repository, in particular how to handle
calculations that are dependant on many other queries or calculations (like missed visits).
* We need to be aware of certain inputs that impact a wide range of queries, and ensure they are passed into the repository and
part of respective cache keys.  One example of this is the `with_exclusions` flag that we have introduced to filter out patients
from our common denominators.
* This sort of approach makes it easy to change out data sources - for example, if we introduce proper ETL based tables for determining control counts, we can subsitute the underlying ControlRateQuery Repository uses. Callers should not have to care at all about the change.
