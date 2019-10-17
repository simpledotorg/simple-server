class PatientListDownloadMailer < ApplicationMailer
  default from: 'help@simple.org'

  def patient_list(recipient_email, model_type, model_name, patients_csv)
    @model_type = model_type
    @model_name = model_name

    subject = I18n.t('patient_list_email.subject', model_type: @model_type, model_name: @model_name)

    file_name = "patient-list_#{model_type}_#{@model_name.strip}_#{I18n.l(Date.current)}.csv"
    attachments[file_name] = {
      mime_type: "text/csv",
      content: patients_csv
    }

    mail(to: recipient_email, subject: subject)
  end
end
