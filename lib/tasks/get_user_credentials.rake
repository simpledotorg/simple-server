# frozen_string_literal: true

desc "Get user credentials to attach to request headers"
task get_user_credentials: :environment do
  abort "This task can only be run in development!" unless Rails.env.development?

  user = User.sync_approval_status_allowed.joins(:phone_number_authentications).sample

  puts "Attach the following request headers to your requests:"
  puts "Authorization: Bearer #{user.access_token}"
  puts "X-User-ID: #{user.id}"
  puts "X-Facility-ID: #{user.registration_facility.id}"
end
