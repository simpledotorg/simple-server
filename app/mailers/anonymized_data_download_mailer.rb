class AnonymizedDataDownloadMailer < ApplicationMailer
  def mail_anonymized_data
    @recipient_name = params[:recipient_name]
    @recipient_email = params[:recipient_email]
    @attachment_data = params[:anonymized_data]
    @resource = params[:resource]
    @facilities = @resource[:facilities]

    @attachment_data.each do |file_name, file_contents|
      next if file_contents.blank?

      attachments[file_name] = {
        mime_type: "text/csv",
        content: file_contents
      }
    end

    mail(subject: subject,
         to: @recipient_email)
  end

  private

  def subject
    if @resource.keys.include?(:district_name)
      I18n.t("anonymized_data_download_email.district_subject",
        district_name: @resource[:district_name],
        recipient_name: @recipient_name)
    else
      I18n.t("anonymized_data_download_email.facility_subject",
        facility_name: @resource[:facility_name],
        recipient_name: @recipient_name)
    end
  end
end
