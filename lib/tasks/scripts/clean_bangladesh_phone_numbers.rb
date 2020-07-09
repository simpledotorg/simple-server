class CleanBangladeshPhoneNumbers
  def self.call(*args)
    new(*args).call
  end

  attr_reader :verbose, :dryrun

  def initialize(verbose: true, dryrun: false)
    @verbose = verbose
    @dryrun = dryrun
  end

  def call
    log "Identified #{eligible_phone_numbers.count} phone numbers with a leading zero"

    if dryrun
      log "Dryrun. Aborting."
      return
    end

    remove_leading_zeros

    log "Complete. Goodbye."
  end

  private

  def remove_leading_zeros
    log "Removing leading zeros from #{eligible_phone_numbers.count} phone numbers..."
    eligible_phone_numbers.each do |phone_number|
      phone_number.update!(number: phone_number.number.delete_prefix("0"))
    end
  end

  def eligible_phone_numbers
    @eligible_phone_numbers ||= PatientPhoneNumber.where("number LIKE '0%'")
  end

  def log(message)
    puts message if verbose
  end
end
