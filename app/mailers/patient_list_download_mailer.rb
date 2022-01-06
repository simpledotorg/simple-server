# frozen_string_literal: true

class PatientListDownloadMailer < ApplicationMailer
  def patient_list(recipient_email, model_type, model_name, patients_csv)
    @model_type = model_type
    @model_name = model_name

    subject = I18n.t("patient_list_email.subject", model_type: @model_type, model_name: @model_name)
    file_name = "patient-list_#{model_type}_#{@model_name.strip}_#{I18n.l(Date.current)}"

    csv_file_name = "#{file_name}.csv"
    zip_archive_name = "#{file_name}.zip"

    attachments[zip_archive_name] = {
      mime_type: "application/zip",
      content: compress_file(csv_file_name, patients_csv)
    }

    mail(to: recipient_email, subject: subject)
  end

  def compress_file(file_name, file_data)
    Zip::OutputStream.write_buffer { |zip|
      zip.put_next_entry(file_name)
      zip.write file_data
    }.string
  end
end
