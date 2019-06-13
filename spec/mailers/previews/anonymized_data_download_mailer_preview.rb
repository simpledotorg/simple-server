# Preview all emails at http://localhost:3000/rails/mailers/anonymized_data_download_mailer
class AnonymizedDataDownloadMailerPreview < ActionMailer::Preview
  def mail_anonymized_data
    AnonymizedDataDownloadMailer.with(user: User.first).mail_anonymized_data
  end
end
