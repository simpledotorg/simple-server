class AnonymizedDataDownloadMailer < ApplicationMailer
  default from: 'help@simple.org'

  def mail_anonymized_data
    recipient_name = params[:recipient_name]
    recipient_email = params[:recipient_email]
    recipient_role = params[:recipient_role]
    attachment_data = params[:anonymized_data]

    binding.pry
    subject = I18n.t('anonymized_data_download_email.subject', recipient_name: recipient_name, recipient_role: recipient_role)
    attachments['sample.csv'] = {
      mime_type: 'text/csv',
      content: attachment_data
    }
    mail(subject: subject,
         to: recipient_email)
  end
end
