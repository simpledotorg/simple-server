require "tasks/scripts/delete_organization_data"

namespace :hard_delete do
  desc "Delete PATH and associated data"
  task :path_data, [:dry_run] => :environment do |_t, args|
    dry_run = args.dry_run || args.dry_run.nil?

    if !SimpleServer.env.production? || CountryConfig.current[:name] != "India"
      abort "Can run only in India production"
    end

    DeleteOrganizationData.delete_path_data("7e896fa8-5e8f-4902-b814-b58d12332d0f", dry_run: dry_run)
  end

  desc "Delete an org and associated data"
  task :organization, [:dry_run, :organization_id] => :environment do |_t, args|
    dry_run = args.dry_run || args.dry_run.nil?
    abort "Org id cannot be blank" if args.organization_id.blank?
    abort "Could not find organization #{organization_id}" unless Organization.find_by(id: organization_id)

    DeleteOrganizationData.call(organization_id: args.organization_id, dry_run: dry_run)
  end
end
