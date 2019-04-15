namespace :exotel_tasks do
  desc 'Whitelist patient phone numbers on Exotel'
  task whitelist_patient_phone_numbers: :environment do
    require 'exotel_tasks/whitelist_phone_numbers'

    data_file = ENV['JSON_FILE_PATH']
    account_sid = ENV['ACCOUNT_SID']
    token = ENV['TOKEN']
    virtual_number = ENV['VIRTUAL_NUMBER']
    batch_size = (ENV['BATCH_SIZE'] || 1000).to_i

    if data_file.blank? || account_sid.blank? || token.blank?
      puts 'Please specify all of: FILE_PATH, ACCOUNT_SID and TOKEN as env vars to continue'
      abort 'Exiting...'
    end

    task = ExotelTasks::WhitelistPhoneNumbers.new(account_sid,
                                                  token,
                                                  data_file)

    logger.tagged('Whitelisting patient phone numbers') do
      logger.debug("Chunking phone numbers into comma-separated batches...")

      task.rearrange_in_batches(batch_size).each_with_index do |batch, idx|
        logger.debug("Starting to process batch \##{idx}")

        data = { :Language => 'en',
                 :VirtualNumber => virtual_number,
                 :Number => batch }
        task.process(data)

        sleep 1
      end

      pp task.stats
      logger.debug("#{task.stats}")
    end
  end
end
