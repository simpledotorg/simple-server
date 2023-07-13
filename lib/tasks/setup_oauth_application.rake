desc "Create a machine user and an OAuth Application"
task :setup_oauth_application, [:name, :organization_id, :client_id, :client_secret] => :environment do |_t, args|
  require "tasks/scripts/create_machine_user"
  require "tasks/scripts/create_oauth_application"

  abort "Requires <name>" unless args[:name].present?
  abort "Requires <client_id>" unless args[:client_id].present?
  abort "Requires <organization_id>" unless args[:client_id].present?
  puts "No client secret given, generating a secret" unless args[:client_secret].present?

  name = args[:name]
  client_id = args[:client_id]
  organization_id = args[:organization_id]
  client_secret = args[:client_secret] || SecureRandom.hex(8)

  begin
    machine_user = CreateMachineUser.create(name, organization_id)
    oauth_application = CreateOAuthApplication.create(name, client_id, client_secret)
    puts "#### OAuth Application ####"
    puts JSON.pretty_generate(oauth_application.attributes)
    puts "#### Machine User ####"
    puts JSON.pretty_generate(machine_user.attributes)
  rescue => e
    puts "Failed to create #{name}: #{e.message}"
  end
end
