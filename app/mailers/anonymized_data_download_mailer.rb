class AnonymizedDataDownloadMailer < ApplicationMailer
  default from: 'help@simple.org'

  def mail_anonymized_data
    recipient_name = params[:recipient_name]
    recipient_email = params[:recipient_email]
    attachment_data = params[:anonymized_data]

    subject = I18n.t('anonymized_data_download_email.subject', recipient_name: recipient_name)

    attachment_data.each do |file_name, file_contents|
      attachments[file_name] = {
        mime_type: 'text/csv',
        content: file_contents
      }
    end

    mail(subject: subject,
         to: recipient_email)
  end
end
