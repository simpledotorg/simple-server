# ADR 11 Rollup summary tables for Dashboards

## Context
Earlier we went with a [materialized view approach](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/008-materialized-views-for-dashboards.md) for dashboard reporting data. This approach has worked out well for the current reports but has limitations in terms of scaling and complexity.

We currently have a need for a new set of dashboard reports that rely on similar sets of data, and anticipate more needs for summary data for monthly and quarterly reports. We'd like to try to find a simpler, more stable, and more scalable approach to making that data easily accessible.

## Decision

We will create rollup summary tables for to capture the "most recent blood pressure per patient per period". These rollup tables will be updated in real-time as blood pressures are captured, removing the need for recurring batch jobs. We will denormalize as much data as we need to to make reporting queries simple and cheap to execute, to prevent the need for any complicated SQL queries or additional data layer caching.

Once the current period has completed, we will treat the data in these rollup tables for that period as immutable. This will let us and our users have more confidence in reports from past periods, as they will not change due to patients moving to different facilities or changes in how we calculate things.

We will focus on the District controlled blood pressure trend report as a first test case for this sort of approach, as it is a key report and one we'd like to gather feedback on as quickly as possible.

## Approach

### Defining the tables

* We will start with the district based reports for BP controlled numbers over time. We will create a rollup table with a schema like the following (consider this a draft, it will change as we get into implementation):
```
id
patient_id
registration_facility_id
blood_pressure_at_facility_id
blood_pressure_id
diastolic
systolic
recorded_at
period_type
period_name
year
```
* `period_type` will be either `M` or `Q` (month or quarter), `period_name` will be either the month name or quarter number, and year will be year.
* We will also start rollup tables to store the total number of registrations per period:
```
id
facility_id
registrations_count
new_registrations_count
period_type
period_name
year
```

* We will add logic to at the lowest level of our model layer to update the above rollup tables immediately after the inserts/updates. We will use [UPSERT](https://wiki.postgresql.org/wiki/UPSERT#.22UPSERT.22_definition) to atomically update or insert the 'most recent record' for these tables wherever possible.
* We will build out a backfill job to fill out these tables for all previous periods.

## Status
Superseded by [016 Reporting Schema](./016-reporting-schema.md)

## Consequences

### Neutral
* We need to be careful to avoid denormalizing calculated values representing domain logic -- for example, we should store the raw blood pressure values, and not a boolean for 'controlled'.
* We should err on the side of storing more data than we think we may need, as we know reporting changes are often fluid and can change frequently. We want to minimize the need for schema changes for small reporting changes
* The notion of an 'assigned facility' is something coming soon, and we should be mindful of how we will take that into account
### Advantages
* Updates to these tables should be relatively easy to implement without database contention.
* Retrieving data from these tables should be fast and simple. Queries should be relatively simple and inexpensive.  We will denormalize whatever data is needed to make queries fast.
* If this approach is successful, we can slowly phase out the materialized views over time with corresponding rollup tables. This can be an incremental rollout based on new reports and scaling demands. This should remove the stress on our database of continual materialized view refreshes.
### Disadvantages
* We will have to iterate quite a bit to get the schemas right for the first round of reports. Adding new columns later on will be expensive in terms of backfills, so we should try to iterate quickly for the first round to flush out problems or missing fields
* We may have to implement some sort of full, back-dated period refresh to handle exceptional cases like large imports of old data.
* Handling `updated` blood pressures where the recorded_at is changed such that the month or quarter changes is tricky, because it involves updating the rollup for the _old_ periods as well. We can handle this if need be but it will require some careful backfill logic.
* We won't be able to handle arbitrary date ranges - i.e. show me a trend report from Jan 20th to March 5th.
