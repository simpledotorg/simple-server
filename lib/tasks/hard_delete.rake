require "tasks/scripts/delete_organization_data"

namespace :hard_delete do
  desc "Delete PATH and associated data"
  task :path_data, [:dry_run] => :environment do |_t, args|
    dry_run = args.dry_run || args.dry_run.nil?

    if !SimpleServer.env.production? || CountryConfig.current[:name] != "India"
      abort "Can run only in India production"
    end

    log "Dry run: #{dry_run}"
    puts "This will delete #{facilities.count} facilities belonging to PATH and all associated data"
    log "Are you sure you want to proceed? (y/n): "
    return unless gets.chomp.downcase == "y"

    DeleteOrganizationData.delete_path_data("7e896fa8-5e8f-4902-b814-b58d12332d0f", dry_run: dry_run)
  end

  desc "Delete an org and associated data"
  task :organization, [:dry_run, :organization_id] => :environment do |_t, args|
    dry_run = args.dry_run || args.dry_run.nil?
    abort "Org id cannot be blank" if args.organization_id.blank?

    organization = Organization.find_by(id: organization_id)
    abort "Could not find organization #{organization_id}" unless organization

    log "Dry run: #{dry_run}"
    log "This will delete the org #{organization.name}, #{facilities.count} facilities and all associated data"
    log "Are you sure you want to proceed? (y/n): "
    return unless gets.chomp.downcase == "y"

    DeleteOrganizationData.call(organization_id: args.organization_id, dry_run: dry_run)
  end
end
