class ExperimentResultsMailer < ApplicationMailer
  def email_report(recipient:, filename:, csv:)
    attachments[file_name] = {
      mime_type: "text/csv",
      content: csv
    }

    mail(to: recipient, subject: "Experiment data export")
  end
end
