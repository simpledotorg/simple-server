namespace :exotel_tasks do
  desc 'Get phone number details from exotel'
  task get_patient_phone_number_details: :environment do
    account_sid = ENV.fetch('ACCOUNT_SID')
    token = ENV.fetch('TOKEN')
    batch_size = ENV.fetch('EXOTEL_UPDATE_PHONE_NUMBER_DETAILS_BATCH_SIZE').to_i

    PatientPhoneNumber.in_batches(of: batch_size) do |batch|
      batch.each do |patient_phone_number|
        UpdatePhoneNumberDetailsJob.perform_later(patient_phone_number.id, account_sid, token)
      end
    end
  end

  desc 'Whitelist patient phone numbers for exotel'
  task whitelist_patient_phone_numbers: :environment do
    account_sid = ENV.fetch('ACCOUNT_SID')
    token = ENV.fetch('TOKEN')
    batch_size = ENV.fetch('EXOTEL_WHITELIST_PHONE_NUMBER_DETAILS_BATCH_SIZE').to_i
    virtual_number = ENV.fetch('EXOTEL_VIRTUAL_NUMBER')

    AutomaticPhoneNumberWhitelistingJob.perform_later(virtual_number, account_sid, token, batch_size)
  end
end
