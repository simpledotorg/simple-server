class AnonymizedDataDownloadMailer < ApplicationMailer
  default from: 'help@simple.org'

  def mail_anonymized_data
    recipient_name = params[:recipient_name]
    recipient_email = params[:recipient_email]
    recipient_role = params[:recipient_role]

    subject = I18n.t('anonymized_data_download_email.subject', recipient_name: recipient_name, recipient_role: recipient_role)
    attachments['sample.csv'] = {
      mime_type: 'text/csv',
      content: test_csv_data
    }
    mail(subject: subject,
         to: recipient_email)
  end

  private

  def test_csv_data
    csv = 'id,name,age,gender,comments'
  end
end
