# frozen_string_literal: true

# Script to move a region (block/woreda or facility) from one parent to another
# This handles all the complexities of:
# - Updating ltree paths for the region and all descendants
# - Clearing caches
# - Recalculating populations
# - Refreshing reporting views
# - Validating the move is safe
#
# Usage:
#   mover = MoveRegion.new(region_slug: "hulla-woreda", new_parent_slug: "southern-zone")
#   mover.move!
#
class MoveRegion
  attr_reader :region, :new_parent, :old_parent, :old_path, :new_path, :affected_facilities_count

  def initialize(region_slug:, new_parent_slug:)
    @region = Region.find_by!(slug: region_slug)
    @new_parent = Region.find_by!(slug: new_parent_slug)
    @old_parent = find_current_parent(@region)
    @old_path = @region.path.to_s

    validate_move!
  end

  def move!(dry_run: false, skip_reporting_refresh: false)
    if dry_run
      perform_dry_run
    else
      perform_move(skip_reporting_refresh: skip_reporting_refresh)
    end
  end

  private

  def perform_dry_run
    Rails.logger.info "=" * 80
    Rails.logger.info "DRY RUN: Move Region Analysis"
    Rails.logger.info "=" * 80

    log_info "Region to move:", region.name
    log_info "Type:", region.region_type
    log_info "Current path:", @old_path
    log_info "Current parent:", @old_parent&.name || "None"
    log_info "New parent:", @new_parent.name

    # Calculate new path
    temp_region = region.dup
    temp_region.reparent_to = @new_parent
    temp_region.send(:initialize_path)
    @new_path = temp_region.path.to_s

    log_info "New path would be:", @new_path

    # Count affected descendants
    descendants = Region.where("path <@ ?::ltree", @old_path)
    log_info "Total affected regions:", descendants.count

    # Break down by type
    Region::REGION_TYPES.each do |type|
      count = descendants.where(region_type: type).count
      log_info "  #{type.capitalize} regions:", count if count > 0
    end

    # Facilities affected
    @affected_facilities_count = region.facility_regions.count
    log_info "Facilities that will move:", @affected_facilities_count

    if @affected_facilities_count > 0
      log_info "\nFacility names:"
      region.facilities.limit(10).each do |facility|
        log_info "  - #{facility.name}"
      end
      log_info "  ... and #{@affected_facilities_count - 10} more" if @affected_facilities_count > 10
    end

    # Sync implications
    log_warning "\n⚠️  SYNC IMPLICATIONS:"
    log_warning "Mobile devices syncing to '#{@old_parent.name}' will no longer receive data from '#{region.name}'"
    log_warning "Mobile devices syncing to '#{@new_parent.name}' will start receiving data from '#{region.name}'"
    log_warning "This will trigger a resync for affected users"

    # Population impact
    if region.estimated_population || region.estimated_diabetes_population
      log_warning "\n⚠️  POPULATION DATA:"
      log_warning "This region has estimated population data that will be recalculated"
      if region.estimated_population
        log_warning "  HTN population: #{region.estimated_population.population}"
      end
      if region.estimated_diabetes_population
        log_warning "  DM population: #{region.estimated_diabetes_population.population}"
      end
    end

    # User access implications
    users_count = count_affected_users
    if users_count > 0
      log_warning "\n⚠️  USER ACCESS:"
      log_warning "#{users_count} users have access to regions in this hierarchy"
      log_warning "Their access permissions may need to be reviewed"
    end

    Rails.logger.info "\n" + "=" * 80
    Rails.logger.info "To perform this move, run: move!(dry_run: false)"
    Rails.logger.info "=" * 80

    {
      region: region.name,
      old_parent: @old_parent&.name,
      new_parent: @new_parent.name,
      old_path: @old_path,
      new_path: @new_path,
      affected_regions: descendants.count,
      affected_facilities: @affected_facilities_count
    }
  end

  def perform_move(skip_reporting_refresh: false)
    result = {}

    ActiveRecord::Base.transaction do
      Rails.logger.info "Starting move of #{region.name} from #{@old_parent&.name} to #{@new_parent.name}"
      Rails.logger.info "=" * 80
      Rails.logger.info "DEBUG: BEFORE saving parent"
      Rails.logger.info "  region.path BEFORE: #{region.path}"
      Rails.logger.info "  region.slug: #{region.slug}"
      Rails.logger.info "  @old_path: #{@old_path}"

      # CRITICAL: Find and store descendant IDs BEFORE we save the parent
      # This ensures we can update them even if paths change during save
      descendants_before = Region.where("path <@ ?::ltree", @old_path).where.not(id: region.id)
      descendant_ids = descendants_before.pluck(:id)
      Rails.logger.info "  Descendants BEFORE save: #{descendants_before.count}"
      Rails.logger.info "  Stored #{descendant_ids.count} descendant IDs for later update"
      descendants_before.limit(5).each do |d|
        Rails.logger.info "    - #{d.name} (#{d.region_type}): #{d.path}"
      end
      Rails.logger.info "=" * 80

      # Step 1: Update the region's parent
      region.reparent_to = @new_parent
      region.save!
      @new_path = region.path.to_s

      Rails.logger.info "=" * 80
      Rails.logger.info "DEBUG: AFTER saving parent"
      Rails.logger.info "  region.path AFTER: #{region.path}"
      Rails.logger.info "  region.slug AFTER: #{region.slug}"
      Rails.logger.info "  @new_path: #{@new_path}"

      # Check what descendants exist AFTER we save
      descendants_after = Region.where("path <@ ?::ltree", @old_path).where.not(id: region.id)
      Rails.logger.info "  Descendants at OLD path after save: #{descendants_after.count}"
      descendants_after.limit(5).each do |d|
        Rails.logger.info "    - #{d.name} (#{d.region_type}): #{d.path}"
      end
      Rails.logger.info "=" * 80

      log_info "Step 1: Updated region parent", "✓"
      result[:region_updated] = true

      # Step 2: Update all descendant paths using the stored IDs
      descendants_count = update_descendant_paths_by_ids(descendant_ids)
      log_info "Step 2: Updated #{descendants_count} descendant paths", "✓"
      result[:descendants_updated] = descendants_count

      # Step 2.5: Update facility model fields (zone, district, state, facility_group_id)
      facilities_updated = update_facility_fields
      log_info "Step 2.5: Updated #{facilities_updated} facility model fields", "✓"
      result[:facilities_updated] = facilities_updated

      # Step 3: Clear caches
      clear_caches
      log_info "Step 3: Cleared caches", "✓"
      result[:caches_cleared] = true

      # Step 4: Recalculate populations
      if should_recalculate_populations?
        recalculate_populations
        log_info "Step 4: Recalculated populations", "✓"
        result[:populations_recalculated] = true
      else
        log_info "Step 4: Population recalculation not needed", "→"
        result[:populations_recalculated] = false
      end

      # Step 5: Log the change
      log_region_move
      log_info "Step 5: Logged region move", "✓"
      result[:logged] = true

      Rails.logger.info "=" * 80
      Rails.logger.info "✅ Successfully moved #{region.name}"
      Rails.logger.info "   From: #{@old_path}"
      Rails.logger.info "   To: #{@new_path}"
      Rails.logger.info "=" * 80
    end

    # Step 6: Refresh reporting views (outside transaction - can take time)
    if skip_reporting_refresh
      Rails.logger.info "Step 6: Skipping reporting views refresh (will be updated by scheduled jobs)"
      log_info "Step 6: Skipped reporting views refresh", "→"
      result[:reporting_refreshed] = false
    else
      Rails.logger.info "Step 6: Refreshing reporting views (this may take a while)..."
      refresh_reporting_views
      log_info "Step 6: Refreshed reporting views", "✓"
      result[:reporting_refreshed] = true
    end

    # Step 7: Run integrity check
    Rails.logger.info "Step 7: Running integrity check..."
    check_integrity
    log_info "Step 7: Integrity check completed", "✓"
    result[:integrity_checked] = true

    result
  rescue => e
    Rails.logger.error "ERROR: Failed to move region: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  def validate_move!
    errors = []

    # Check if region exists
    errors << "Region not found" unless region
    errors << "New parent not found" unless new_parent

    return if errors.any? # Can't continue validation

    # Check if new parent is valid
    unless valid_parent_type?
      errors << "Cannot move #{region.region_type} to #{new_parent.region_type}. " \
                "Expected parent type: #{expected_parent_type}"
    end

    # Check if trying to move to itself or descendant
    if new_parent.path.to_s.start_with?(@old_path)
      errors << "Cannot move region to itself or its own descendant"
    end

    # Check if trying to move to the same parent (no-op move)
    current_parent = find_current_parent(region)
    if current_parent && current_parent.id == new_parent.id
      errors << "Region is already in #{new_parent.name}. Cannot move to the same parent."
    end

    # Check if region is root
    if region.region_type == "root"
      errors << "Cannot move root region"
    end

    # Check if new parent is root (only organizations can be children of root)
    if new_parent.region_type == "root" && region.region_type != "organization"
      errors << "Only organizations can be direct children of root"
    end

    if errors.any?
      raise ArgumentError, "Invalid move: #{errors.join(", ")}"
    end

    true
  end

  def valid_parent_type?
    expected_parent_type == new_parent.region_type
  end

  def expected_parent_type
    case region.region_type
    when "organization" then "root"
    when "state" then "organization"
    when "district" then "state"
    when "block" then "district"
    when "facility" then "block"
    end
  end

  def find_current_parent(region)
    parent_type = expected_parent_type
    return nil unless parent_type

    region.public_send("#{parent_type}_region")
  rescue NoMethodError
    nil
  end

  def update_descendant_paths_by_ids(descendant_ids)
    Rails.logger.info "=" * 80
    Rails.logger.info "DEBUG: update_descendant_paths_by_ids called"
    Rails.logger.info "  Updating #{descendant_ids.count} descendants by ID"
    Rails.logger.info "  @old_path: #{@old_path}"
    Rails.logger.info "  @new_path: #{@new_path}"

    updated_count = 0
    failed_count = 0

    Region.where(id: descendant_ids).find_each do |descendant|
      old_descendant_path = descendant.path.to_s
      Rails.logger.info "  Processing descendant #{descendant.id} (#{descendant.name})"
      Rails.logger.info "    Current path: #{old_descendant_path}"

      # Try to replace the old parent path with new parent path
      # The old path might have changed if slug changed, so we need to be flexible
      if old_descendant_path.include?(@old_path)
        # Direct replacement if old_path is still in there
        new_descendant_path = old_descendant_path.sub(@old_path, @new_path)
        Rails.logger.info "    New path (direct): #{new_descendant_path}"
        descendant.update_column(:path, new_descendant_path)
        updated_count += 1
      else
        # Old path not found - this is the problem we're trying to solve
        Rails.logger.warn "    WARNING: old_path '#{@old_path}' not found in '#{old_descendant_path}'"

        # Try to find any path segment that matches the region slug
        region_path_segment = region.slug.tr("-", "_")
        if old_descendant_path.include?(region_path_segment)
          Rails.logger.info "    Found region segment '#{region_path_segment}' in path"
          # Extract the path up to and including our region, then append the rest
          path_parts = old_descendant_path.split(".")
          region_index = path_parts.index { |p| p.include?(region_path_segment) }

          if region_index
            # Build new path: new parent path + region segment + rest of path
            new_path_parts = @new_path.split(".") + path_parts[region_index + 1..]
            new_descendant_path = new_path_parts.join(".")
            Rails.logger.info "    New path (reconstructed): #{new_descendant_path}"
            descendant.update_column(:path, new_descendant_path)
            updated_count += 1
          else
            Rails.logger.error "    ERROR: Could not find region in path parts"
            failed_count += 1
          end
        else
          Rails.logger.error "    ERROR: Could not find any matching segment"
          failed_count += 1
        end
      end
    end

    Rails.logger.info "  Successfully updated #{updated_count} descendants"
    Rails.logger.info "  Failed to update #{failed_count} descendants" if failed_count > 0
    Rails.logger.info "=" * 80
    updated_count
  end

  def update_descendant_paths
    Rails.logger.info "=" * 80
    Rails.logger.info "DEBUG: update_descendant_paths called"
    Rails.logger.info "  @old_path: #{@old_path}"
    Rails.logger.info "  @new_path: #{@new_path}"
    Rails.logger.info "  region.path after save: #{region.path}"
    Rails.logger.info "  region.slug: #{region.slug}"

    # Find all descendants (children, grandchildren, etc.)
    # Use ActiveRecord instead of raw SQL for reliability
    descendants = Region
      .where("path <@ ?::ltree", @old_path)
      .where.not(id: region.id)

    Rails.logger.info "  Query: SELECT * FROM regions WHERE path <@ '#{@old_path}'::ltree AND id != '#{region.id}'"
    Rails.logger.info "  Found #{descendants.count} descendants to update"

    if descendants.count == 0
      # Debug: Check if any facilities exist and what their paths are
      all_facilities = Region.where(region_type: "facility")
      Rails.logger.info "  DEBUG: Total facilities in DB: #{all_facilities.count}"
      all_facilities.limit(5).each do |f|
        Rails.logger.info "    - #{f.name} (#{f.id}): #{f.path}"
        # Check if this facility's path contains any part of our region's slug
        if f.path.to_s.include?(region.slug.tr("-", "_"))
          Rails.logger.info "      ^ This facility path contains '#{region.slug.tr("-", "_")}'"
        end
      end
    end

    updated_count = 0
    descendants.find_each do |descendant|
      old_descendant_path = descendant.path.to_s
      new_descendant_path = old_descendant_path.sub(@old_path, @new_path)

      Rails.logger.info "Updating descendant #{descendant.id}: #{old_descendant_path} -> #{new_descendant_path}"

      # Use update_column to bypass callbacks and validations
      descendant.update_column(:path, new_descendant_path)
      updated_count += 1
    end

    Rails.logger.info "Updated #{updated_count} descendant paths"
    Rails.logger.info "=" * 80
    updated_count
  end

  def clear_caches
    # Clear Rails cache for affected regions
    affected_regions = [region, new_parent, old_parent].compact

    # Add state regions if we're moving districts or below
    if region.region_type.in?(["district", "block", "facility"])
      begin
        affected_regions << new_parent.state_region
      rescue
        nil
      end
      begin
        affected_regions << old_parent&.state_region
      rescue
        nil
      end
    end

    affected_regions.uniq.each do |r|
      Rails.cache.delete_matched("#{r.cache_key}/*")
    end

    # Clear cached_ancestors only for regions whose ancestors actually changed
    # This includes the moved region and all its descendants
    Rails.logger.info "Clearing cached_ancestors for moved region and descendants..."
    regions_to_clear = [region] + Region.where("path <@ ?::ltree", region.path.to_s).to_a
    Rails.logger.info "Clearing #{regions_to_clear.count} cached_ancestors..."

    regions_to_clear.each do |r|
      Rails.cache.delete("#{r.cache_key}/ancestors")
    end

    # Clear the power_user_region_access cache used by Reports::RegionsController
    # This cache stores the entire region tree structure
    Rails.logger.info "Clearing power_user_region_access cache..."
    Rails.cache.delete("users/power_user_region_access")
  end

  def update_facility_fields
    # Get all affected facility regions (the moved region + its descendants)
    affected_regions = [region] + Region.where("path <@ ?::ltree", region.path.to_s).to_a
    affected_facility_regions = affected_regions.select { |r| r.region_type == "facility" }

    Rails.logger.info "Updating facility model fields for #{affected_facility_regions.count} facilities..."

    updated_count = 0
    affected_facility_regions.each do |facility_region|
      facility = facility_region.source
      next unless facility

      # Calculate new values from region hierarchy
      block_region = facility_region.block_region
      district_region = facility_region.district_region
      state_region = facility_region.state_region

      # Update facility fields
      updates = {}
      updates[:zone] = block_region&.name if block_region
      updates[:district] = district_region&.name if district_region
      updates[:state] = state_region&.name if state_region

      # Update facility_group_id (FacilityGroup is associated with district region)
      if district_region && district_region.source_type == "FacilityGroup"
        facility_group = district_region.source
        updates[:facility_group_id] = facility_group&.id if facility_group
      end

      # Batch update without validations/callbacks for performance
      if updates.any?
        facility.update_columns(updates)
        updated_count += 1
      end
    end

    Rails.logger.info "Updated #{updated_count} facility records"
    updated_count
  end

  def should_recalculate_populations?
    # Recalculate if moving districts (affects state populations)
    region.region_type.in?(["district", "block"])
  end

  def recalculate_populations
    # Recalculate state-level populations for both old and new states
    states_to_recalculate = []

    if region.region_type == "district"
      # Moving a district affects state populations
      states_to_recalculate << new_parent if new_parent.region_type == "state"
      states_to_recalculate << old_parent if old_parent&.region_type == "state"
    elsif region.region_type.in?(["block", "facility"])
      # Moving blocks/facilities affects their state populations
      begin
        states_to_recalculate << new_parent.state_region
      rescue
        nil
      end
      begin
        states_to_recalculate << old_parent&.state_region
      rescue
        nil
      end
    end

    states_to_recalculate.compact.uniq.each do |state|
      state.recalculate_state_population! if state.respond_to?(:recalculate_state_population!)
      state.recalculate_state_diabetes_population! if state.respond_to?(:recalculate_state_diabetes_population!)
    end
  end

  def refresh_reporting_views
    RefreshReportingViews.call

    # Queue background jobs to refresh partitioned tables for all historical months
    # This ensures reporting data is correct across all time periods after the move
    refresh_partitioned_tables_historically
  rescue => e
    Rails.logger.error "Failed to refresh reporting views: #{e.message}"
    # Don't fail the whole operation if reporting refresh fails
  end

  def refresh_partitioned_tables_historically
    Rails.logger.info "Queueing background jobs to refresh historical reporting data..."

    # Get all reporting months
    reporting_months = ReportingMonth.all
    reporting_tables = ["reporting_patient_blood_pressures", "reporting_patient_blood_sugars"]

    jobs_queued = 0
    reporting_months.each do |month|
      reporting_tables.each do |table|
        # Queue async job (doesn't block, runs in background)
        RefreshReportingPartitionedTableJob.perform_async(month.month_date.to_s, table)
        jobs_queued += 1
      end
    end

    Rails.logger.info "Queued #{jobs_queued} background jobs to refresh partitioned tables"
  rescue => e
    Rails.logger.error "Failed to queue partitioned table refresh jobs: #{e.message}"
    # Don't fail the whole operation if background job queueing fails
  end

  def check_integrity
    RegionsIntegrityCheck.call
  rescue => e
    Rails.logger.error "Integrity check failed: #{e.message}"
    # Don't fail the operation, just log
  end

  def log_region_move
    # Log to Rails logger for audit trail
    Rails.logger.info({
      event: "region_moved",
      region_id: region.id,
      region_name: region.name,
      region_type: region.region_type,
      old_parent_id: old_parent&.id,
      old_parent_name: old_parent&.name,
      new_parent_id: new_parent.id,
      new_parent_name: new_parent.name,
      old_path: @old_path,
      new_path: @new_path,
      timestamp: Time.current
    }.to_json)
  end

  def count_affected_users
    # Count users who have access to regions in this hierarchy
    User.joins(:user_authentications)
      .where(user_authentications: {authenticatable_type: "PhoneNumberAuthentication"})
      .count { |u|
        # Check if user has access to any region in the old or new hierarchy
        u.accessible_region_ids(:manage).intersect?([old_parent&.id, new_parent.id, region.id].compact)
      }
  rescue
    0 # If there's an error counting, return 0
  end

  def log_info(message, status = nil)
    status_icon = status ? " [#{status}]" : ""
    Rails.logger.info "  #{message}#{status_icon}"
  end

  def log_warning(message)
    Rails.logger.warn message
  end
end
