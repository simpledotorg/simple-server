require "tasks/scripts/delete_organization_data"

namespace :hard_delete do
  desc "Delete an org and associated data"
  task :organization, [:organization_id, :dry_run] => :environment do |_t, args|
    abort "This script is currently disabled, to enable it, raise a PR and make necessary code changes."

    # hard_delete:organization[<org_id>] for a dry run
    # hard_delete:organization[<org_id>,false] otherwise
    dry_run =
      if args.dry_run == "false"
        false
      else
        args.dry_run || args.dry_run.nil?
      end

    abort "Org id cannot be blank" if args.organization_id.blank?

    organization = Organization.find_by(id: args.organization_id)
    abort "Could not find organization #{args.organization_id}" unless organization

    puts "Dry run: #{dry_run}"
    puts "This will delete the org #{organization.name}, its facilities and all associated data"
    puts "Are you sure you want to proceed? (y/n): "
    abort unless $stdin.gets.chomp.downcase == "y"

    DeleteOrganizationData.call(organization: organization, dry_run: dry_run)
  end
end
