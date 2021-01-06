class PatientListDownloadMailer < ApplicationMailer
  def patient_list(recipient_email, model_type, model_name, patients_csv)
    @model_type = model_type
    @model_name = model_name

    subject = I18n.t("patient_list_email.subject", model_type: @model_type, model_name: @model_name)

    file_name = "patient-list_#{model_type}_#{@model_name.strip}_#{I18n.l(Date.current)}.csv"
    zip_file_name = "#{file_name}.zip"
    zip_file = compress_file(file_name, patients_csv)

    attachments[zip_file_name] = {
      mime_type: "application/zip",
      content: zip_file
    }

    mail(to: recipient_email, subject: subject)
  end

  def compress_file(file_name, file_data)
    output_buffer = Zip::OutputStream.write_buffer { |zip|
      zip.put_next_entry(file_name)
      zip.write file_data
    }

    output_buffer.string
  end
end
