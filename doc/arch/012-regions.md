### Why do we need Regions?

Our current reporting / organizational structures is as follows, from highest to lowest, with Patients belonging to Facilities.

Organization -> FacilityGroup -> Facility

We know we are missing some levels in that hierarchy, namely States and Blocks:

Organization -> State -> FacilityGroup -> Block -> Facility

All of these levels can share some things: they have a name, a URL friendly slug, and a description. Most importantly, they allow us to group patients and their data into meaningful slices for reports.

We also know that these "levels" may be different from country to country, not only in their name but also in terms of their actual structure. Bangladesh or Ethiopia may not have Blocks, or may have a different name for that sort of group.

Its clear we shouldn't keep adding levels in the structure as one-offs, because they all share common behavior and the one-off approach won't scale to other countries. Given that, we should start working towards a better domain that lets us model Regions in a consistent, unified way.

### What are Regions?

A Region is a hierarchical grouping object with a recursive relationship. A region has many child regions, and a region belongs to one parent region, except for the root region. In other systems they are often called something like organization, department, or division. Since our groupings are _mostly_ geographic, and the term "organization" is already taken, Region seems like a good term for Simple.org

### How to get there?

The short term plan is to add Regions, and insert them into the hierarchy at the root (for an entire app instance) and for States to begin the migration process. We would modify existing models to work as if they are regions, so that we can start using a unified interface via duck typing. The long term goal is for a Region to take the place of Orgs, FacilityGroup, and Facility for grouping.

This PR tackles that short term plan. Here is a sketch of the relationships for how things would look after this PR is merged:

![regions-v1](https://user-images.githubusercontent.com/69/88346204-63272480-cd0d-11ea-880c-066408e91717.png)

Long term, Regions would handle the entirety of our organizational structure, and would also make assigning roles to users easier. Regions would be used for root, organization, state, district, block, facility group, and facility, and whatever other level we need. We could extract domain objects from the current Facility model, with the first candidate being the Address and Geo location info. We would probably keep around the facility and facility group models, as they would hold specific data and relationships that are only relevant to that specific level.

Here is a sketch of how things could look long term, after what would be many PRs. Obviously this is all very hand wavey and further down the line; we would want to iterate towards something like this and refine the design as we went.

![regions-future-state](https://user-images.githubusercontent.com/69/88346422-e5174d80-cd0d-11ea-91c7-45485bd69054.png)

**Feedback welcome!** If this seems like a good plan, this first PR should be pretty easy to ship as a first step. The main thing we'd want to be careful about is the data migration in production.

### References

[Organization Structures](https://martinfowler.com/apsupp/accountability.pdf) from Fowlers' _Analysis Patterns_ distills many of the common patterns we are dealing with here in terms of Org hierarchies and knowledge levels.

* [user roles (take 3)](#1173) - this becomes easier as regions come into play
* https://app.clubhouse.io/simpledotorg/story/132/block-level-reports
* https://app.clubhouse.io/simpledotorg/story/454/state-level-reports

