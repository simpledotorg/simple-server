require "tasks/scripts/move_facility_data"
require "tasks/scripts/discard_invalid_appointments"
require "tasks/scripts/move_region"

namespace :data_fixes do
  desc "Move all data from a source facility to a destination facility"
  task :move_data_from_source_to_destination_facility, [:source_facility_id, :destination_facility_id] => :environment do |_t, args|
    source_facility = Facility.find(args.source_facility_id)
    destination_facility = Facility.find(args.destination_facility_id)
    results = MoveFacilityData.new(source_facility, destination_facility).move_data
    puts "[DATA FIXED]"\
         "source: #{source_facility.name}, destination: #{destination_facility.name}, "\
         "#{results}"
  end

  desc "Move all data recorded by a user from a source facility to a destination facility"
  task :move_user_data_from_source_to_destination_facility, [:user_id, :source_facility_id, :destination_facility_id] => :environment do |_t, args|
    user = User.find(args.user_id)
    source_facility = Facility.find(args.source_facility_id)
    destination_facility = Facility.find(args.destination_facility_id)
    results = MoveFacilityData.new(source_facility, destination_facility, user: user).move_data
    puts "[DATA FIXED]"\
         "user: #{user.full_name}, source: #{source_facility.name}, destination: #{destination_facility.name}, "\
         "#{results}"
  end

  desc "Clean up invalid scheduled appointments (multiple scheduled appointments for a patient)"
  task :discard_invalid_scheduled_appointments, [:dry_run] => :environment do |_t, args|
    dry_run =
      args.dry_run == "true"

    puts "This is a dry run" if dry_run

    patients_ids = Appointment.where(status: "scheduled").group(:patient_id).count.select { |_k, v| v > 1 }.keys

    Patient.with_discarded.where(id: patients_ids).each do |patient|
      DiscardInvalidAppointments.call(patient: patient, dry_run: dry_run)
    end
  end

  desc "Move a region (block/woreda or facility) from one parent to another - DRY RUN"
  task :move_region_dry_run, [:region_identifier, :new_parent_identifier] => :environment do |_t, args|
    puts "=" * 80
    puts "DRY RUN: Move Region"
    puts "=" * 80
    puts ""

    # Smart lookup - accepts both slugs and names
    region =
      Region.find_by(slug: args.region_identifier) ||
      Region.find_by(name: args.region_identifier)

    new_parent =
      Region.find_by(slug: args.new_parent_identifier) ||
      Region.find_by(name: args.new_parent_identifier)

    raise "Region not found: #{args.region_identifier}" unless region
    raise "New parent not found: #{args.new_parent_identifier}" unless new_parent

    puts "Found:"
    puts "  Region: #{region.name} (#{region.region_type}, slug: #{region.slug})"
    puts "  New parent: #{new_parent.name} (#{new_parent.region_type}, slug: #{new_parent.slug})"
    puts ""

    mover = MoveRegion.new(
      region_slug: region.slug,
      new_parent_slug: new_parent.slug
    )

    mover.move!(dry_run: true)

    puts ""
    puts "=" * 80
    puts "To execute this move, run:"
    puts "bundle exec rake data_fixes:move_region[\"#{args.region_identifier}\",\"#{args.new_parent_identifier}\"]"
    puts ""
    puts "Or for production via Capistrano:"
    puts "bundle exec cap <env> deploy:rake task=data_fixes:move_region[\"#{args.region_identifier}\",\"#{args.new_parent_identifier}\"]"
    puts "=" * 80
  rescue => e
    puts "ERROR: #{e.message}"
    puts e.backtrace.join("\n") if ENV["DEBUG"]
    exit 1
  end

  desc "Move a region (block/woreda or facility) from one parent to another - EXECUTE"
  task :move_region, [:region_identifier, :new_parent_identifier] => :environment do |_t, args|
    puts "=" * 80
    puts "MOVE REGION"
    puts "=" * 80
    puts ""
    puts "⚠️  WARNING: This will move the region and all its descendants!"
    puts ""

    # Smart lookup - accepts both slugs and names
    region =
      Region.find_by(slug: args.region_identifier) ||
      Region.find_by(name: args.region_identifier)

    new_parent =
      Region.find_by(slug: args.new_parent_identifier) ||
      Region.find_by(name: args.new_parent_identifier)

    raise "Region not found: #{args.region_identifier}" unless region
    raise "New parent not found: #{args.new_parent_identifier}" unless new_parent

    puts "Found:"
    puts "  Region: #{region.name} (#{region.region_type}, slug: #{region.slug})"
    puts "  New parent: #{new_parent.name} (#{new_parent.region_type}, slug: #{new_parent.slug})"
    puts ""

    mover = MoveRegion.new(
      region_slug: region.slug,
      new_parent_slug: new_parent.slug
    )

    # Show dry run first
    puts "Analyzing move..."
    mover.move!(dry_run: true)

    puts ""
    puts "=" * 80
    puts "Are you sure you want to proceed? Type 'yes' to continue:"
    puts "=" * 80

    puts ""
    if $stdin.gets.chomp.downcase == "yes"
      puts "Executing move..."
      result = mover.move!(dry_run: false)

      puts ""
      puts "=" * 80
      puts "✅ MOVE COMPLETED SUCCESSFULLY"
      puts "=" * 80
      puts ""
      puts "Summary:"
      puts "  Region updated: #{result[:region_updated]}"
      puts "  Descendants updated: #{result[:descendants_updated]}"
      puts "  Caches cleared: #{result[:caches_cleared]}"
      puts "  Populations recalculated: #{result[:populations_recalculated]}"
      puts "  Reporting views refreshed: #{result[:reporting_refreshed]}"
      puts "  Integrity check: #{result[:integrity_checked]}"
      puts ""
    else
      puts "❌ Move cancelled"
      exit 0
    end
  rescue => e
    puts ""
    puts "=" * 80
    puts "❌ ERROR: #{e.message}"
    puts "=" * 80
    puts e.backtrace.join("\n") if ENV["DEBUG"]
    exit 1
  end
end
