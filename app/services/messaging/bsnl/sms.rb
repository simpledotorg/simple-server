class Messaging::Bsnl::Sms < Messaging::Channel
  def self.communication_type
    Communication.communication_types[:sms]
  end

  # variable_content: A map that takes the values to be interpolated
  # in the templates. For example: { facility_name: "Facility A", patient_name: "Patient" }
  # TODO: This should also create communications and return them.
  def send_message(recipient_number:, dlt_template_name:, variable_content:)
    template = Messaging::Bsnl::DltTemplate.new(dlt_template_name)
    template.check_approved
    variables = template.sanitised_variable_content(variable_content)

    Messaging::Bsnl::Api.new.send_sms(
      recipient_number: recipient_number,
      dlt_template: template,
      key_values: variables
    ).then { |response| handle_api_errors(response, template, variables) }
  end

  private

  def handle_api_errors(response, template, variables)
    error = response["Error"]
    if error.present?
      raise Messaging::Bsnl::Error.new("#{error} Error on template #{template.name} with content #{variables}")
    else
      response
    end
  end
end
