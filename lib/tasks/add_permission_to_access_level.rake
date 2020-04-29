# frozen_string_literal: true

require 'tasks/scripts/add_permission_to_access_level'

desc 'Add a permission to users with a specified access level'
task :add_permission_to_access_level,
     [:permission, :access_level] => :environment do |_t, args|
  # bundle exec add_permission_to_access_level[:view_my_facilities,:supervisor]

  permission = args[:permission]
  access_level = args[:access_level]

  unless AddPermissionToAccessLevel.new(permission, access_level).valid_permission?
    abort 'Please add the permission to app/policies/permissions.rb, under the appropriate access level before running'\
          ' this task'
  end
end
