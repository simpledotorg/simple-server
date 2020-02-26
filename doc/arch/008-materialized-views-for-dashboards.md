# Materialized views for Dashboards

## Context
In Dec 2019, we decided to add the new "My Facilities Dashboards" for CVHOs and other health officials.
These dashboards make a lot more data available to users than the previously existing Cohort reports.
At the same time, they need to be significantly more performant than the existing reports.
With the expectation that the size of data would grow rapidly, the following approaches were considered:
* Extract-Transform-Load data pipeline
* Materialized Views

## Decision
An ETL pipeline pushing data to a reporting database is the ideal solution for this purpose but would involve a lot of effort to set up and maintain.

Materialized views are a good intermediate solution, since they give us many of the benefits of an ETL pipeline,
without the overhead of specialised infrastructure. We may need to review this decision if materialized view refreshes become very expensive.
We will use [scenic](https://github.com/scenic-views/scenic) to manage the views.

## Approach
### Defining the views
* For each dashboard, we may define a view to represent its data, or choose to query existing views.
* The views will slice data by the time periods we need to query by (eg: `days`, `months`, `quarters`).
* Ideally, the view definitions should be free of domain logic. (eg: the definition of a `hypertensive` blood pressure shouldn't be tied to the materialized view definition)
### Using the views
* Views will have to be refreshed periodically. The period can vary depending on the dashboard's requirement.
* Each dashboard will consist of a query object, the necessary materialized views for its data, and templates to render the data appropriately.
* The query object will provide an interface to fetch the data from the views. These objects should return active record relations to allow for composability and reuse.
* Example of a [query object for new registrations](https://github.com/simpledotorg/simple-server/blob/b0724c59e32bad4150f216378b024a1e98df5f8e/app/queries/my_facilities/registrations_query.rb)
## Status

Accepted

## Consequences

* Materialized view refresh times will scale with the size of the database tables. Currently `blood_pressures` is the most significant table.
    Eg. The `LatestBloodPressuresPerPatientPerMonth` refresh takes 82569.7ms for 7557416 records in the `blood_pressures` table. This duration will increase with the number of bps.
* View refresh order is important, dependant views should be refreshed only after their parent views to ensure consistency.
    * [Rake task](https://github.com/simpledotorg/simple-server/blob/b0724c59e32bad4150f216378b024a1e98df5f8e/lib/tasks/refresh_materialized_db_views.rake) to refresh the views in order
* Views will have to be refreshed in the reporting timezone, to ensure that data is sorted into the appropriate time periods. A view per timezone will be needed to support multiple reporting timezones in a single deployment.
* A change in the view definition can be carried out by creating a new migration. Scenic can generate these migrations for us.
* Any domain logic leaking into the views will mean that the view definitions need to be updated when the domain logic changes.
    * Eg: If a view contains the definition of a `hypertensive` patient, the view will need to be updated if the definition of `hypertensive` changes.
