class TelemedReportMailer < ApplicationMailer
  def email_report(period_start:, period_end:, report_filename:, report_csv:)
    @period_start = period_start
    @period_end = period_end
    @recipient_emails = ENV.fetch("TELEMED_REPORT_EMAILS")
    @subject = "Telemed report for #{@period_start} to #{@period_end}"

    file_name = report_filename
    attachments[file_name] = {
      mime_type: "text/csv",
      content: report_csv
    }

    if Flipper.enabled?(:automated_telemed_report) && @recipient_emails
      mail(to: @recipient_emails, subject: @subject)
    end
  end
end
