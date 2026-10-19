# Moving Regions Between Parents

This guide explains how to move regions (blocks/woredas or facilities) from one parent to another in the region hierarchy.

## Overview

The region move capability allows you to restructure the administrative hierarchy by moving regions and all their descendants to a new parent. This is useful when:

- Administrative boundaries change (e.g., a woreda moves from one zone to another)
- Facilities are reassigned to different blocks
- Organizational restructuring requires moving entire districts

## Important Considerations

### What Gets Moved

When you move a region, the following happens:
- The region's `path` (ltree) is updated
- All descendant regions' paths are updated
- Rails caches are cleared
- State-level populations are recalculated (if moving districts or blocks)
- Reporting views are refreshed
- An integrity check is run

### Impact on Mobile Sync

**CRITICAL**: Moving regions affects mobile app sync boundaries!

- Users syncing to the **old parent** will **stop** receiving data from the moved region
- Users syncing to the **new parent** will **start** receiving data from the moved region
- This will trigger a **resync** for affected users

**Recommendation**: Communicate with field teams before performing moves in production.

### Impact on User Access

Users with region-based access permissions may lose or gain access to facilities after a move. Review user permissions after the move.

## Usage

### Step 1: Dry Run (REQUIRED)

**Always run a dry run first** to analyze the impact:

```bash
# Using region names (recommended - easier to remember)
bundle exec rake data_fixes:move_region_dry_run["Hulla Woreda","Southern Zone"]

# Or using slugs (also works)
bundle exec rake data_fixes:move_region_dry_run[hulla-woreda,southern-zone]

# Production (via Capistrano)
bundle exec cap ethiopia-production deploy:rake task=data_fixes:move_region_dry_run["Hulla Woreda","Southern Zone"]
```

**Note:** The task accepts both region names (with quotes) or slugs (without quotes).

**Example output:**
```
================================================================================
DRY RUN: Move Region Analysis
================================================================================
  Region to move: Hulla Woreda
  Type: block
  Current path: root.ethiopia_moh.sidama.northern_zone.hulla_woreda
  Current parent: Northern Zone
  New parent: Southern Zone
  New path would be: root.ethiopia_moh.sidama.southern_zone.hulla_woreda
  Total affected regions: 11
    Block regions: 1
    Facility regions: 10
  Facilities that will move: 10

  Facility names:
    - Hulla Health Center
    - Gono Health Post
    - Bira Health Post
    ... and 7 more

⚠️  SYNC IMPLICATIONS:
Mobile devices syncing to 'Northern Zone' will no longer receive data from 'Hulla Woreda'
Mobile devices syncing to 'Southern Zone' will start receiving data from 'Hulla Woreda'
This will trigger a resync for affected users

⚠️  USER ACCESS:
15 users have access to regions in this hierarchy
Their access permissions may need to be reviewed
================================================================================
```

### Step 2: Execute the Move

After reviewing the dry run, execute the move:

```bash
# Using region names (recommended)
bundle exec rake data_fixes:move_region["Hulla Woreda","Southern Zone"]

# Or using slugs (also works)
bundle exec rake data_fixes:move_region[hulla-woreda,southern-zone]

# Production (via Capistrano)
bundle exec cap ethiopia-production deploy:rake task=data_fixes:move_region["Hulla Woreda","Southern Zone"]
```

**The task will:**
1. Show the dry run analysis again
2. Ask for confirmation: "Type 'yes' to continue"
3. Execute the move if you confirm
4. Show a summary of what was updated

**Example output:**
```
================================================================================
MOVE REGION
================================================================================

⚠️  WARNING: This will move the region and all its descendants!

Analyzing move...
[... shows dry run analysis ...]

================================================================================
Are you sure you want to proceed? Type 'yes' to continue:
================================================================================
yes

Executing move...
  Step 1: Updated region parent [✓]
  Step 2: Updated 10 descendant paths [✓]
  Step 3: Cleared caches [✓]
  Step 4: Recalculated populations [✓]
  Step 5: Logged region move [✓]
Step 6: Refreshing reporting views (this may take a while)...
  Step 6: Refreshed reporting views [✓]
Step 7: Running integrity check...
  Step 7: Integrity check completed [✓]

================================================================================
✅ MOVE COMPLETED SUCCESSFULLY
================================================================================

Summary:
  Region updated: true
  Descendants updated: 10
  Caches cleared: true
  Populations recalculated: true
  Reporting views refreshed: true
  Integrity check: true
```

## Flexible Input

The `move_region` tasks are smart and accept both:
- **Region names** (e.g., "Hulla Woreda", "Southern Zone") - use quotes
- **Region slugs** (e.g., hulla-woreda, southern-zone) - no quotes needed

The task will automatically detect whether you provided a name or slug and find the correct region.

**Examples:**
```bash
# Using names (recommended for readability)
rake data_fixes:move_region["Hulla Woreda","Southern Zone"]

# Using slugs (works too)
rake data_fixes:move_region[hulla-woreda,southern-zone]

# Mixed (name and slug)
rake data_fixes:move_region["Hulla Woreda",southern-zone]
```

## Valid Parent-Child Relationships

The script validates that you're moving regions to the correct parent type:

| Region Type | Valid Parent Type |
|------------|------------------|
| organization | root |
| state | organization |
| district | state |
| block | district |
| facility | block |

**Examples:**
- ✅ Move a block (woreda) to a district (zone)
- ✅ Move a facility to a block
- ✅ Move a district to a state
- ❌ Move a block to a state (invalid - blocks must go to districts)
- ❌ Move a facility to a district (invalid - facilities must go to blocks)

## Validations

The script performs these safety checks:

1. **Parent type validation**: Ensures the new parent is the correct type
2. **Self-reference check**: Cannot move a region to itself
3. **Descendant check**: Cannot move a region to one of its own descendants
4. **Root check**: Cannot move the root region
5. **Organization under root**: Only organizations can be direct children of root

## What Happens During the Move

### 1. Transaction Start
All changes are wrapped in a database transaction. If anything fails, everything rolls back.

### 2. Update Region Path
```ruby
region.reparent_to = new_parent
region.save!
```

The `reparent_to` callback updates the region's ltree path.

### 3. Update Descendant Paths
```sql
UPDATE regions
SET path = text2ltree(
  replace(ltree2text(path), 'old_path', 'new_path')
)
WHERE path <@ 'old_path'::ltree
  AND id != 'region_id'
```

Uses PostgreSQL's ltree functions to efficiently update all descendant paths.

### 4. Clear Caches
Clears Rails cache for:
- The moved region
- The new parent
- The old parent
- Parent state regions (if applicable)

### 5. Recalculate Populations
If moving districts or blocks:
- Recalculates HTN and DM populations for affected states
- Updates `estimated_population` records

### 6. Log the Move
Creates an audit log entry:
```json
{
  "event": "region_moved",
  "region_id": "...",
  "region_name": "Hulla Woreda",
  "old_parent_name": "Northern Zone",
  "new_parent_name": "Southern Zone",
  "old_path": "root.ethiopia_moh.sidama.northern_zone.hulla_woreda",
  "new_path": "root.ethiopia_moh.sidama.southern_zone.hulla_woreda",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### 7. Refresh Reporting Views (Outside Transaction)
Calls `RefreshReportingViews.call` to update:
- `reporting_facilities`
- `reporting_patient_states`
- All other materialized views

This step can take several minutes for large datasets.

### 8. Integrity Check
Runs `RegionsIntegrityCheck.call` to verify:
- No duplicate regions
- No missing regions
- Hierarchy is consistent

## Troubleshooting

### Error: "Cannot move block to state"
**Cause**: You're trying to move a region to an invalid parent type.

**Solution**: Check the valid parent-child relationships table above. For example, blocks must move to districts, not states.

### Error: "Cannot move region to itself or its own descendant"
**Cause**: You're trying to move a region to one of its children or itself.

**Solution**: Verify the new parent is not a descendant of the region you're moving.

### Move succeeds but reporting dashboards show wrong data
**Cause**: Reporting views may not have refreshed completely.

**Solution**: Manually refresh reporting views:
```bash
bundle exec rake reporting:refresh_reporting_views
```

### Users can't access facilities after move
**Cause**: User access permissions are region-based.

**Solution**: Review and update user access grants to include the new parent regions.

### Mobile devices not syncing moved facilities
**Cause**: Mobile app sync boundaries changed.

**Solution**:
1. Verify the facility's `sync_region_id` is correct
2. Ask affected users to force a resync in the app

## Testing

Run the test suite to verify the move functionality:

```bash
bundle exec rspec spec/lib/tasks/scripts/move_region_spec.rb
```

The tests cover:
- Valid and invalid moves
- Descendant path updates
- Population recalculation
- Cache clearing
- Transaction rollback on errors
- Real-world scenarios (e.g., moving Hulla Woreda)

## Example: SIMPLEETH-40 (Moving Hulla Woreda)

This is the real-world example from the ticket:

### Context
- **Region**: Sidama
- **Current Zone**: Northern Zone
- **New Zone**: Southern Zone
- **Woreda to move**: Hulla Woreda
- **Facilities affected**: All facilities in Hulla Woreda

### Commands

**1. Find the region slugs:**
```bash
# SSH to Ethiopia production and run Rails console
bundle exec rails console

# Find the regions
woreda = Region.find_by(name: "Hulla Woreda", region_type: "block")
southern_zone = Region.find_by(name: "Southern Zone", region_type: "district")

puts "Woreda slug: #{woreda.slug}"
puts "Southern Zone slug: #{southern_zone.slug}"
exit
```

**2. Run dry run:**
```bash
bundle exec cap ethiopia-production deploy:rake task=data_fixes:move_region_dry_run["Hulla Woreda","Southern Zone"]
```

**3. Review the output carefully**

**4. Execute the move:**
```bash
bundle exec cap ethiopia-production deploy:rake task=data_fixes:move_region["Hulla Woreda","Southern Zone"]
```

**5. Verify the move:**
```bash
# SSH to production and check
bundle exec rails console

woreda = Region.find_by(name: "Hulla Woreda")
puts "Current parent: #{woreda.district_region.name}"  # Should be "Southern Zone"
puts "Current path: #{woreda.path}"  # Should include "southern_zone"
```

## Post-Move Checklist

- [ ] Verify region moved successfully (check path in console)
- [ ] Verify all facility paths updated
- [ ] Check reporting dashboards show correct data
- [ ] Verify integrity check passed
- [ ] Test user access to moved facilities
- [ ] Monitor mobile sync for affected users
- [ ] Communicate changes to field teams
- [ ] Update any documentation referencing the old structure

## See Also

- [Adjusting Sync Boundaries](../wiki/adjusting-sync-boundaries.md)
- [Region Architecture Decision](../arch/012-regions.md)
- [Moving Patient Data Between Facilities](move-patient-data-between-facilities.md)
