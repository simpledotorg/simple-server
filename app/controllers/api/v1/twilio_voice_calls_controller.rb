class Api::V1::TwilioVoiceCallsController < APIController
  skip_before_action :authenticate, only: [:initiate, :connect]
  http_basic_authenticate_with name: ENV['TWILIO_CALLBACK_USERNAME'], password: ENV['TWILIO_CALLBACK_PASSWORD']
  before_action :set_user, :verify_incoming_from_nurse

  def initiate
    render status: :ok, xml: gather_patient_phone_number_response
  end

  def connect
    render status: :ok, xml: dail_pateint_phone_number_response
  end

  private

  def set_user
    @user = User.find_by(phone_number: incoming_from_number)
  end

  def verify_incoming_from_nurse
    render status: :ok, xml: unknown_user_response unless @user.present?
  end

  def gather_patient_phone_number_response
    Twilio::TwiML::VoiceResponse.new do |r|
      r.gather(action: url_for(action: :connect),
               method: 'POST',
               finish_on_key: '#')
    end
  end

  def dail_pateint_phone_number_response
    Twilio::TwiML::VoiceResponse.new do |r|
      r.dial(number: connect_to_phone_number)
    end
  end

  def unknown_user_response
    Twilio::TwiML::VoiceResponse.new do |r|
      r.say(message: I18n.t('voice_call.unknown_user'), voice: I18n.t('voice_call.twilio.voice'))
      r.hangup
    end
  end

  def incoming_from_number
    params.require('From')
  end

  def connect_to_phone_number
    params.require('Digits')
  end
end