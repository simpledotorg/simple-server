class Messaging::Bsnl::Sms < Messaging::Channel
  def self.communication_type
    Communication.communication_types[:sms]
  end

  def self.get_message_statuses
    BsnlDeliveryDetail.where("created_at > ?", 2.days.ago).in_progress.find_each do |detailable|
      BsnlSmsStatusJob.perform_async(detailable.message_id)
    end
  end

  # variable_content: A map that takes the values to be interpolated
  # in the templates. For example: { facility_name: "Facility A", patient_name: "Patient" }
  def send_message(recipient_number:, dlt_template_name:, variable_content:, &with_communication_do)
    template = approved_template(dlt_template_name)

    track_metrics do
      create_communication(
        recipient_number,
        send_bsnl_message(recipient_number, template, variable_content),
        template.id,
        &with_communication_do
      )
    end
  end

  private

  def approved_template(template_name)
    Messaging::Bsnl::DltTemplate.new(template_name).tap(&:check_approved)
  end

  def send_bsnl_message(recipient_number, template, variable_content)
    variables = template.sanitised_variable_content(variable_content)

    Messaging::Bsnl::Api.new.send_sms(
      recipient_number: recipient_number,
      dlt_template: template,
      key_values: variables
    ).tap { |response| raise_api_errors(response, template) }
  end

  def raise_api_errors(response, template)
    error = response["Error"]
    if error.present?
      raise Messaging::Bsnl::ApiError.new("#{error} Error sending SMS for #{template.name}")
    end
  end

  def create_communication(recipient_number, response, template_id, &with_communication_do)
    ActiveRecord::Base.transaction do
      BsnlDeliveryDetail.create_with_communication!(
        message_id: response["Message_Id"],
        recipient_number: recipient_number,
        dlt_template_id: template_id
      ).tap do |communication|
        with_communication_do&.call(communication)
      end
    end
  end
end
