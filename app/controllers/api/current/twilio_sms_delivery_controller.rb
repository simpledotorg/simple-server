class Api::Current::TwilioSmsDeliveryController < ApplicationController
  before_action :set_request_validator
  skip_before_action :verify_authenticity_token

  def create
    if valid_request?
      TwilioSMSDeliveryDetail.where(session_id: params['SmsSid']).update(update_params)
      head :ok
    else
      head :forbidden
    end
  end

  private

  def update_params
    details = { result: delivery_status }
    details.merge(delivered_on: DateTime.now) if delivery_status == TwilioSMSDeliveryDetail.results[:delivered]

    details
  end

  def delivery_status
    params['SmsStatus'] || params['MessageStatus'] || TwilioSMSDeliveryDetail.results[:unknown]
  end

  def set_request_validator
    @validator = Twilio::Security::RequestValidator.new(ENV.fetch('TWILIO_AUTH_TOKEN'))
  end

  def valid_request?
    @validator.validate(request.original_url,
                        request.request_parameters,
                        request.headers['X-Twilio-Signature'])
  end
end
