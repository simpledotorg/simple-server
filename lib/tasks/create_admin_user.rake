# frozen_string_literal: true

desc "Create an admin user"
task :create_admin_user, [:name, :email, :password] => :environment do |_t, args|
  require "tasks/scripts/create_admin_user"

  abort "Requires <name>" unless args[:name].present?
  abort "Requires <email>, <password>" unless args[:email].present? && args[:password].present?

  name = args[:name]
  email = args[:email]
  password = args[:password]

  begin
    CreateAdminUser.create_owner(name, email, password)
  rescue => e
    puts "Failed to create #{email}: #{e.message}"
  end
end
