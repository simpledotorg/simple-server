# Data API

## Status
Proposed

_Note that since this requires operational changes, and potentially
hiring folks into the ops team who can do this, this is not a purely
engineering decision alone._

Related documents:
- [Sustainability Strategy](https://docs.google.com/document/d/11R8fx9v46DSRtVOZpAWU2JXqY0NxFA0PKOnzr3RdDpk/edit)
- [Downloads page design](https://www.figma.com/file/UQnTudZe7AYxvveDTnRcrh/Dashboard-(Explorations)?node-id=1%3A9870): Needs fixing.

## Context
We provide many downloads for CVHOs via the Simple Dashboard. The
purposes of these vary from needing a generic report, to building the
exact report that needs to be submitted to higher-ups in healthcare
administration. As we move across countries, these customisations
proliferate into an unsustainable process for the Simple product team.

In addition to the downloads, there are many requests for one-off
reports in CSV/Excel form, which are essentially the same data in the
reports, but filtered or disaggregated in some way. These are also
expensive to the product team, and aren't sustainable in the long
term. Metabase is being used for many one-off reports by a small set
of people, however it cannot be self-served to all the dashboard users
without the access control layer that the dashboard has.

Here is the list of bespoke downloads we provide on the dashboard:
- Patient lists
    - [Patient list](https://api-sandbox.simple.org/reports/patient_lists/ch-cascabel-village?report_scope=facility)
    - [Patient list with med history](https://api-sandbox.simple.org/reports/patient_lists/ch-cascabel-village?medication_history=true&report_scope=facility)
    - [Overdue list](https://api-sandbox.simple.org/appointments.csv?district_slug=alder-county&facility_id=73fafb72-0a8a-43c5-b668-3fcc4bb5541c&per_page=20+per+page&search_filters%5B%5D=only_less_than_year_overdue)
- Region reports
    - [Whatsapp graphics](https://api-sandbox.simple.org/reports/regions/facility/ch-cascabel-village/graphics.png?quarter=4&year=2021)
    - [Quarterly cohort report](https://api-sandbox.simple.org/reports/regions/facility/ch-cascabel-village/download.csv?period=quarter)
    - [Monthly cohort report](https://api-sandbox.simple.org/reports/regions/facility/ch-cascabel-village/download.csv?period=month)
    - [Monthly district report](https://api-sandbox.simple.org/reports/regions/district/ashoka-south/monthly_district_report.zip)
    - [Monthly facility data](https://api-sandbox.simple.org/reports/regions/district/ashoka-south/monthly_district_data_report.csv)
- Drug Stock reports
    - [Drug stock](https://api-sandbox.simple.org/my_facilities/drug_stocks.csv)
    - [Drug consumption](https://api-sandbox.simple.org/my_facilities/drug_consumption.csv)


## Decision
In order to be
[sustainable](https://docs.google.com/document/d/11R8fx9v46DSRtVOZpAWU2JXqY0NxFA0PKOnzr3RdDpk/edit),
we need to enable the ops team to create the custom CSVs and answer
one-off requests independently.

A Data API, which exposes _all_ the reporting data that Simple uses to
build the dashboards might be a good way to create this self-serving
mechanism. The idea is to provide all the data in the hands of the
users, so that they may customize it as they see fit.

Since we aren't seeing direct benefits of the API without the
downloads interface, this will live only inside the dashboard to begin
with.

We will create the following APIs:
- /data/v1/patients.csv:
    - all the data in `reporting_patient_states`
    - some history of observations (BP, BS, PD, App)
    - HTN risk level (to be rolled into patient_states)
    - overdue days (to be rolled into patient_states)
- /data/v1/regions.csv:
    - Has all the data in `reporting_facility_states` /
      `reporting_quarterly_facility_states`
- /data/v1/drug-stocks.csv:
    - Has all the data in `drug_stocks`, denormalized with `protocol_drugs`

They will all be filterable using the parameters:
- `region_id`: uuid of a state, district, block, or facility region. Should this be a list?
- `period_type`: month/quarter
- `month_date/period`: range in period_type

All the APIs will go through the same authenticationi layer, which
decides access to:
- APIs
- Regions

### Documentation
We will have a translation layer that renames the columns to keys in
the API appropriately. And all the APIs will be documented in detail,
and source the documentation from the same YAML file used to define
the columns in the database. The documentation will be available in
the downlaods page on the dashboard.

### Performance considerations
Reading and downloading large swaths of data can be slow. Here are few
considerations to keep in mind to explore while building this:
- Email vs direct downloads: we currently email the patient line lists
- Restricting periods and regions for performance: a drop with last
  1/3/6 months perhaps? Disallow state level downloads?
- Using the read replica for downloads: so that transactions aren't
  impacted by this
- Uplaoding CSVs to S3, or storing them locally to avoid repeated
  computation on the same requests.

### Release
Following the release of these APIs, we will deprecate the downloads
on all other pages, and begin suggesting users to use this new
interface instead. Once the users have built custom reports from the
standard downloads, we can begin to remove them.

## Consequences
- If we decide to expose the data API without the dashboard, the
  dashboard auth needs to be made API friendly
