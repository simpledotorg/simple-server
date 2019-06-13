class AnonymizedDataDownloadService
  def execute
    AnonymizedDataDownloadMailer.mail_anonymized_data.deliver_later
  end

  private

  def anonymize_data
    # anonymize the data here - district/facility level
  end
end