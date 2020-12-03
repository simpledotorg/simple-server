require "tasks/scripts/delete_organization_data"

namespace :hard_delete do
  desc "Delete PATH and associated data"
  task :path_data, [:dry_run] => :environment do |_t, args|
    # This is a temporary rake task to delete PATH specifically since
    # an earlier cleanup cleared only the Org and FGs. This deletes
    # the associated data only.
    dry_run =
      if args.dry_run == "false"
        false
      else
        args.dry_run || args.dry_run.nil?
      end

    if !SimpleServer.env.production? || CountryConfig.current[:name] != "India"
      abort "Can run only in India production"
    end

    puts "Dry run: #{dry_run}"
    puts "This will delete all facilities belonging to PATH and associated data"
    puts "Are you sure you want to proceed? (y/n): "
    abort unless $stdin.gets.chomp.downcase == "y"

    DeleteOrganizationData.delete_path_data("7e896fa8-5e8f-4902-b814-b58d12332d0f", dry_run: dry_run)
  end

  desc "Delete an org and associated data"
  task :organization, [:dry_run, :organization_id] => :environment do |_t, args|
    dry_run = args.dry_run || args.dry_run.nil?
    abort "Org id cannot be blank" if args.organization_id.blank?

    organization = Organization.find_by(id: organization_id)
    abort "Could not find organization #{organization_id}" unless organization

    puts "Dry run: #{dry_run}"
    puts "This will delete the org #{organization.name}, #{facilities.count} facilities and all associated data"
    puts "Are you sure you want to proceed? (y/n): "
    abort unless $stdin.gets.chomp.downcase == "y"

    DeleteOrganizationData.call(organization_id: args.organization_id, dry_run: dry_run)
  end
end
