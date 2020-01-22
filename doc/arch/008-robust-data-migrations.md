# Robust Data Migrations

## Context

On January 20, 2020, the team became aware that a data migration that needed to be executed along with a prior
production deployment was never run in production. In order to rectify this, the team ran the required data migration on
the evening of January 20. Since the task was CPU (and perhaps memory) intensive, the task ran for ~8 hours overnight,
and required constant monitoring from the team to ensure that the task wasn't affecting the regular performance of the
Simple Server. After the task was completed, it was noted that the Simple Server _was_ impacted by the task.

References

* [Slack conversation](https://simpledotorg.slack.com/archives/CFHMC60P5/p1579524825012500)

The problems that this ADR aims to tackle are the following:

* A required data migration was not run after the corresponding production deployment
* Data migrations require constant supervision to monitor server performance and correct failures
* The Simple Server's performance was degraded during the execution of the data migration

## Decision

### Enforcing data migration execution

In order to better enforce the execution of data migrations, we will invoke them using the
[`data-migrate`](https://github.com/ilyakatz/data-migrate) gem. This will ensure that data migrations are run with the
same reliability as database migrations, while still allowing database migrations to be run or rolled back independently
if necessary. For example, we may ship a data migration that looks like this.

```ruby
class UpdateNilensoBPs < ActiveRecord::Migration[5.1]
  def up
    BPUpdater.perform(facility: "Nilenso") # An associated service class that performs the data migration
  end

  def down
    Rails.logger.info("This data migration will not be reversed. Good luck!")
  end
end
```

We will need to take care with our file management. [See below](#consequences).

### Reliable hands-off execution

We will use background jobs to execute data migrations in an asynchronous, atomic, and repeatable fashion. Ideally, the
data migration will be split up into as small atomic parts as possible, and each part will be executed in its own
background job. For example, a task to update 1000 records will be executed using 1000 Sidekiq jobs, one for each
record.

```ruby
# good
affected_records.each do |record|
  UpdateJob.perform_later(record)
end

# bad - not atomic
BulkUpdateJob.perform_later(affected_records)

# bad - not asynchronous
Updater.perform_right_now(affected_records)
```

Using atomic background jobs will have several advantages.

* Failed jobs will be retried automatically with sensible exponential back-off
* We avoid the use of very-long-running processes on the server (which could also result in very-long-running database
  connections)
* It becomes easier to monitor the progress of the migration through the Sidekiq dashboard
* The execution of the data migration can be easily throttled, paused, or halted

We will need to take care of our Sidekiq queues. [See below](#consequences).

### Other beneficial traits

**Idempotence:** Ideally, the data migration task should be repeatable indefinitely without changing the end result.
Idempotent tasks will ensure that even if we have to abandon the migration in a half-finished state (eg. Redis falls
down and background jobs are lost), we should be able to re-run the data migration without requiring any code changes.

```ruby
# good
BloodPressure.where(recorded_at: nil).each do |bp|
  bp.touch(:recorded_at)
end

# bad - not idempotent
BloodPressure.where(id: affected_ids).each do |bp|
  bp.update(systolic: bp.systolic + 10)
end
```

## Status

Accepted

## Consequences

**Regarding the use of database migrations:** We will have to take care to manage the data migration service classes
(like `BPUpdater` above) with care. We may not be able to simply remove them from the codebase after execution, as that
would invalidate the migration file, causing `rails db:migrate` to start failing on any local or production instances
that are far behind. We propose the use of a `lib/data_migrations` or `lib/services/data` directory to permanently house
all data-migration-related service classes, even if they are one-off tasks.

**Regarding the use of background jobs:** The notable risks of using Sidekiq to executed data migrations are listed
below, along with measures to mitigate or eliminate these risks.

* Redis could run out of memory, causing regular jobs to be dropped - We should validate how much memory will be
  required in a non-production environment. Based on our findings, we should either provision enough memory to our Redis
  instance, or split up the data migration into appropriate batches to ensure we do not encounter Redis OOM errors.
* The influx of migration jobs could overwhelm regular job execution - We should ensure that all data migration
  background jobs are executed in a separate Sidekiq queue. This will allow us to throttle them separately from the
  regular background jobs executed by the Simple Server.
