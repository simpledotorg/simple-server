class Api::Current::ExotelCallSessionsController < ApplicationController
  after_action :report_http_status

  def create
    unless valid_patient_phone_number?
      respond_in_plain_text(:bad_request) and return
    end

    session = CallSession.new(params[:From], parse_patient_phone_number)
    if session.authorized?
      session.save(params[:CallSid])
      respond_in_plain_text( :ok)
    else
      respond_in_plain_text(:forbidden)
    end
  end

  private

  def parse_patient_phone_number
    params[:digits].tr('"', '')
  end

  def valid_patient_phone_number?
    parse_patient_phone_number.scan(/\D/).empty?
  end

  def respond_in_plain_text(status)
    head status, content_type: 'text/plain'
  end

  def report_http_status
    NewRelic::Agent.increment_metric("#{controller_name}/#{action_name}/#{response.status}")
  end
end
