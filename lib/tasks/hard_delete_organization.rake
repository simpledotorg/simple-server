require "tasks/scripts/delete_organization_data"

desc "Delete an org and associated data"
task :hard_delete_organization, [:organization_id] => :environment do |_t, args|
  organization = Organization.find_by(id: args.organization_id)
  if organization
    DeleteOrganizationData.call(organization)
  else
    Rails.logger.info "Organization #{args.organization_id} not found"
  end
end
