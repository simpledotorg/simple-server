# Regions Hierarchy

## Date 

October 2020 (accepted)

_Note: this document is being written retroactively to explain a core change in our domain model that has since been implemented...the October date refers to when this decision was accepted._
## Context

Medical officers, nurses, administers, and developers of Simple often want to group patients into geographic and administrative regions. This helps with generating relevant reports for the dashboard as well as with syncing the right amount of data for the offline-first mobile app. 

Our domain model (as of late 2020) groups patients into three broad hierarchical models, from largest to smallest: `Organization -> FacilityGroup -> Facility`:

* An Organization is the highest level - it corresponds to the country or state wide medical program running Simple.
* A FacilityGroup is a grouping of facilities - in practice it has corresponded to a [district](https://en.wikipedia.org/wiki/District), an administrative division with broad geographic boundaries.
* A Facility is a particular hospital, clinic, or medical practice.

Over time Simple has developed a need for more fine grained groupings of patients for reporting, sync, and general categorization. The old model is too coarse-grained and simplistic.

Our mobile app sync has been built around FacilityGroup. As we have grown, syncing all patients within a FacilityGroup loads far too much data -- sometimes tens of thousands of patients. This can overload mobile phones and introduce many UX challenges. Most Simple app users work with hundreds or maybe a thousand of patients over the course of a week, not 10k+.

In the admin UI, there are many users who want to monitor performance at different levels than the district or facility level. Some admin users should have access to levels above or below the FacilityGroup that do not yet exist. For example, in India some users should have reports access at the [state level](https://en.wikipedia.org/wiki/States_and_union_territories_of_India), which is above the district (ie FacilityGroup). The current model does not support this.

Given all this, it will be useful to be able to generalize the grouping of patients into "Regions". A Region is a geographic group of patients that can contain other regions.  All regions share some things from Simple's perspective: they have a parent region, a name, a unique slug (for URLs), and a description. More importantly, they allow us to group patients and their data into meaningful slices for reports and mobile app usage.

## Decision

We will create a new table (`regions`) and ActiveRecord model (`Region`). Regions will have a single parent region, except for the "root" region which will have a null parent region. A Region can have many children regions. This means a Region has a self-referential has-many relationship. Since the relationships are consistent and standardized, things like reports, navigation, and region management becomes simpler and more intuitive. 

Our Region model will follow the hierarchy we need for India, as it is our largest deployment. This model is:

`root -> organization -> state -> district -> block -> facility`

An example of this would be 

`root -> IHCI -> Maharashtra -> Nagpur -> Bhadravati -> [hospital / clinic name]`

A region can belong to an optional "source" model, which in practice will be an Organization, FacilityGroup, or a Facility. This helps us as we transition to a Regions-centered domain model - we need to know the 'legacy' models that many of the patient related models refer to.  For example. there are many records that refer to a `facility_id` to determine where patients were registered or treated.

In the long term, the Region model can completely replace FacilityGroup, as they will contain entirely duplicate data. A Region will most likely _not_ replace the Facility model, because a Facility contains specific data and behavior relating to medical facilities that are not genreally applicable to regions. Some examples of this include facility size, type, and OPD load.

## Approach

We will create a `regions` table and corresponding ActiveRecord model, and write a backfill script to create regions for corresponding Facilities and FacilityGruops. We will copy data from the corresponding source models to Regions as needed during the transition. Over time, we can deprecate and remove legacy string fields such as `state` and `zone` (ie block), and replace them with first class Regions.

The sync API and mobile app will be changed to support region level syncing instead of FacilityGroup syncing. Eventually, we will rewrite the admin interface to create region models instead of FacilityGroups, and FacilityGroups can be phased out completely.
## Consequences

Simple will have more fine grained groupings of patients, which will be more powerful and flexible but also more complicated. The backfill and sync process will be tricky, especially during the interim period.

Determining a region hiearchy that suits different countries and organizations will be a challenge - for now we have elected to use a structure based on India, which is Simple's largest deployment.

Introducing regions could add unnecessary complexity for smaller deployments that do not yet have the need for them. For example, some countries don't need or want to display 'block' level reports.

Our authorization model would work well with regions, as a user could have an `access_level` on a particular region, and the access would flow through to children regions. We would need to do some transition work to accomplish this.

We are deliberately building Regions as a straight-forward hiearchrial grouping, knowing there are many other ways to view patient health data that may not align with our Region model. For the purposes of Simple we want to simplify and pick a consistent path forward. We know that other more nuanced systems can come later as needed.

## Status

Accepted, implemented and in place as of March 2021. The backfill has completed and the ongoing sync is in place. We have not yet deprecated the legacy zone/state fields or the FacilityGroup model.

## References

[Organization Structures](https://martinfowler.com/apsupp/accountability.pdf) from Fowlers' _Analysis Patterns_ distills many of the common patterns we are dealing with here in terms of Org hierarchies and knowledge levels.

