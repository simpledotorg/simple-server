# Preview all emails at http://localhost:3000/rails/mailers/anonymized_data_download_mailer
class AnonymizedDataDownloadMailerPreview < ActionMailer::Preview
  def mail_anonymized_data
    recipient_name = 'test_admin'
    recipient_email = 'test_admin@admins.org'

    AnonymizedDataDownloadMailer
      .with(recipient_name: recipient_name, recipient_email: recipient_email, anonymized_data: { 'patients.csv' => [] })
      .mail_anonymized_data
  end
end
