class Api::Current::TwilioSmsDeliveryController < ApplicationController
  before_action :validate_request
  skip_before_action :verify_authenticity_token

  def create
    existing_session = TwilioSmsDeliveryDetail.where(session_id: params['SmsSid'])

    if existing_session.blank?
      head :not_found
    else
      existing_session.first.update(update_params)
      head :ok
    end
  end

  private

  def update_params
    details = { result: delivery_status }
    details.merge!(delivered_on: DateTime.now) if delivery_status == TwilioSmsDeliveryDetail.results[:delivered]

    details
  end

  def delivery_status
    params['SmsStatus'] || params['MessageStatus'] || TwilioSmsDeliveryDetail.results[:unknown]
  end

  def validate_request
    validator = Twilio::Security::RequestValidator.new(ENV.fetch('TWILIO_REMINDERS_ACCOUNT_AUTH_TOKEN'))
    unless validator.validate(request.original_url,
                              request.request_parameters,
                              request.headers['X-Twilio-Signature'])
      head :forbidden
    end
  end
end
