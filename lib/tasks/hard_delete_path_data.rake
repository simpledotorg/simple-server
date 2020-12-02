require "tasks/scripts/delete_organization_data"

desc "Delete PATH and associated data"
task hard_delete_path_data: :environment do
  # if !SimpleServer.env.production? || CountryConfig.current[:name] != "India"
  #   abort "Can run only in India production"
  # end

  DeleteOrganizationData.delete_path_data("7e896fa8-5e8f-4902-b814-b58d12332d0f")
end
