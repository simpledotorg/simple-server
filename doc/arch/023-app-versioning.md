# Versioning, Release Plan and Maintainance

## Status

Accepted

## Context

Recent work invites us into making Simple a product. In line with this, we would need to version the app alongside the already existing [API and Schema Versioning](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/003-api-versioning.md). We would use this version to mark different Docker images; our preferred mode of delivery.

## Decision

1. The app version should be separate from the API version.
  1. The repository would maintain a mapping between app version and api version
1. The API versioning should stick to one number: v3, v4, and so on. Every other aspect of 003 should hold as well
1. Calendar-backed Semantic Versioning. We would version the app using the `YY.MINOR.PATCH` scheme
1. The app version would begin from version 25.2.1 at the commit of the first release-cut
  1. 1 minor release per quarter
1. Release process would be managed through branches
  1. All engineers would stick to conventional commits; this would be enforced by CI
  1. Every minor release would be supported for one year only after its release
  1. Patch releases would be cherry-picked from the main branch into the release branches.

## Details

### (1.1) Example Version Mapping

| app   | api | notes           |
| ---   | --- | ---             |
| 1.0.0 | v4  | Product Release |
| 1.2.3 | v5  | New API routes  |

### (3 & 4) Calendar-backed Semantic Versioning

With this scheme, we aim to communicate clearly to clients and engineers aloke the moment when a release was cut. The format we are going with is `YY.MINOR.PATCH`. Like the API versioning, the app versioning does not track major releases.

> [!CAUTION]
> A direct consequence of this is that we're committing to keep the app free of breaking changes throughout a calendar year.

- The `YY` bit indicates time.
- `MINOR` is bumped to indicate new feature(s). We aim to plan this per quarter, to give the team time to marinate a feature out.
- `PATCH` is bumped when there's a bugfix or a security fix (think "chore"). Patch releases may be more frequent that minor releases, and may be less planned.

`25.2.1` is the agreed starting point.

### Release Process

**[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)**. To help our releases, engineers must stick to a deterministic form of commit messages. This would help tooling, down the line, to figure out which commits should make it into the next release cut. Without this, we incur some manual work in figuring out these commits.

**What's in a release?** Simple mainly releases according to `MINOR.PATCH`. Our versioning only prepends `YY` to this to hint what year this release came in. What goes into `MINOR` and `PATCH` is already detailed in the previous section. Operationally, the proposed mapping looks below

| Release | Commit | Content                  |
| ---     | ---    | ---                      |
| `MINOR` | `feat` | New Features             |
| `PATCH` | `fix`  | bug- and security- fixes |

**Release Branches**. When a new release is to be cut, a branch would be created from master. The naming convention for these branches would be `releases/YY.MINOR/PATCH`. These branches would have CI tacked on to them which builds out the release image for that particular release. Patch releases would be cherry-picked onto these branches from master. All things being equal, we are to set a date for these releases and try to meet that date. Where we cannot meet the date, appropriate communication should be sent out to all stakeholders about why this date is not met, and a new scheduled date we promise to commit to.

**Maintenance**. With release branches, we commit to maintaining the branch for **one (1) year** after release. This time is known as the "maintenance period". Within this maintenance period, Simple commits to updating the release with bug fixes, and security fixes. These fixes would be added to the release branches, and a new docker image would be created for that minor version. At the end of the maintenance period, the release branch reaches end-of-life. At this point, Simple no longer promises to update the release with bug fixes. The community can take it on from here and do their own patches.

