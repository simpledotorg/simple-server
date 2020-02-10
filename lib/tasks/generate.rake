namespace :generate do
  desc 'Generate fake data; Example: rake "generate:fake_data'
  task fake_data: :environment do
    User.where(role: [ENV['ACTIVE_GENERATED_USER_ROLE'], ENV['INACTIVE_GENERATED_USER_ROLE']])
        .each { |user| PopulateFakeDataJob.perform_async(user.id) }
  end
end
