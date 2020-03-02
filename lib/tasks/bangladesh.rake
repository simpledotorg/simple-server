namespace :bangladesh do
  desc 'Format all patient phone numbers correctly'
  task correct_phone_numbers: :environment do
    exit 0 unless Rails.application.config.country[:name] == 'Bangladesh'

    Patient.find_each do |patient|
      CorrectBangladeshPhoneNumberJob.perform_later(patient)
    end
  end
end
