class AnonymizedDataDownloadService
  def initialize(recipient_name, recipient_email, recipient_role)
    @recipient_name = recipient_name
    @recipient_email = recipient_email
    @recipient_role = recipient_role
  end

  def execute
    # anonymize data here

    # send mail here
    AnonymizedDataDownloadMailer
      .with(recipient_name: @recipient_name, recipient_email: @recipient_email, recipient_role: @recipient_role)
      .mail_anonymized_data
      .deliver_later
  end

  private

  def anonymize_data
    # anonymize the data here - district/facility level
  end
end