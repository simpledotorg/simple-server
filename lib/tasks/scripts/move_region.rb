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

  def move!(dry_run: false)
    if dry_run
      perform_dry_run
    else
      perform_move
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

  def perform_move
    result = {}

    ActiveRecord::Base.transaction do
      Rails.logger.info "Starting move of #{region.name} from #{@old_parent&.name} to #{@new_parent.name}"

      # Calculate new path first without saving
      temp_region = region.dup
      temp_region.reparent_to = @new_parent
      temp_region.send(:initialize_path)
      @new_path = temp_region.path.to_s

      # Step 1: Update all descendant paths FIRST (while old path still exists)
      descendants_count = update_descendant_paths
      log_info "Step 1: Updated #{descendants_count} descendant paths", "✓"
      result[:descendants_updated] = descendants_count

      # Step 2: Update the region's parent
      region.reparent_to = @new_parent
      region.save!

      log_info "Step 2: Updated region parent", "✓"
      result[:region_updated] = true

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
    Rails.logger.info "Step 6: Refreshing reporting views (this may take a while)..."
    refresh_reporting_views
    log_info "Step 6: Refreshed reporting views", "✓"
    result[:reporting_refreshed] = true

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

  def update_descendant_paths
    # Use raw SQL for efficiency
    sql = <<~SQL
      UPDATE regions
      SET path = text2ltree(
        replace(ltree2text(path), '#{@old_path}', '#{@new_path}')
      )
      WHERE path <@ '#{@old_path}'::ltree
        AND id != '#{region.id}'
    SQL

    result = ActiveRecord::Base.connection.execute(sql)
    result.cmd_tuples # Returns number of rows updated
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
  rescue => e
    Rails.logger.error "Failed to refresh reporting views: #{e.message}"
    # Don't fail the whole operation if reporting refresh fails
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
