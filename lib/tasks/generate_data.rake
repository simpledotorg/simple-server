namespace :generate_data do
  desc 'Generate seed data; Example: rake "generate_data:seed'
  task seed: :environment do
    User.where(role: PopulateFakeDataJob::FAKE_DATA_USER_ROLE)
        .each { |user| PopulateFakeDataJob.perform_async(user.id) }
  end
end
