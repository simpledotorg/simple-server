# frozen_string_literal: true

require 'tasks/scripts/add_permission_to_access_level'

desc 'Add a permission to users with a specified access level'
# Usage example: bundle exec rake add_permission_to_access_level[view_my_facilities,supervisor]

task :add_permission_to_access_level,
     [:permission, :access_level] => :environment do |_t, args|

  permission = args[:permission].to_sym
  access_level = args[:access_level].to_sym

  new_permissions = AddPermissionToAccessLevel.new(permission, access_level)

  unless new_permissions.valid?
    abort 'Please add the permission to app/policies/permissions.rb, under the appropriate access level before running'\
          ' this task'
  end

  created_permissions = new_permissions.create
  users_with_new_permissions = created_permissions.flatten.map(&:user).uniq.sort_by(&:full_name)

  puts "Created #{created_permissions.count} permission records for the following #{users_with_new_permissions.count} "\
       "users: #{users_with_new_permissions.map(&:full_name)}"
end
