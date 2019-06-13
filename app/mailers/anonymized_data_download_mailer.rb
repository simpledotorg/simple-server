class AnonymizedDataDownloadMailer < ApplicationMailer
  default from: 'help@simple.org'

  def mail_anonymized_data
    #@user = params[:user]
    subject = I18n.t('anonymized_data_download_email.subject', full_name: 'timmy')
    attachments['sensitive_data.csv'] = File.read('/Users/timmyjose/Desktop/sensitive_data.csv')
    mail(subject: subject,
         to: 'timmy@nilenso.com')
  end
end
