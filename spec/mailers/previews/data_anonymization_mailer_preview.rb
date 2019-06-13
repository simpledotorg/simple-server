# Preview all emails at http://localhost:3000/rails/mailers/data_anonymization_mailer
class DataAnonymizationMailerPreview < ActionMailer::Preview
  def mail_anonymized_data
    DataAnonymizationMailer.with(user: User.first).mail_anonymized_data
  end
end
