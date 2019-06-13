class AnonymizedDataDownloadMailer < ApplicationMailer
  default from: 'help@simple.org'

  def mail_anonymized_data
    @user = params[:user]
    subject = 'Anonymized Data dump: Requested by User %{full_name}'
    mail(subject: subject,
         from: from,
         to: @user.email)
  end
end
