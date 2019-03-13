class Api::Current::ExotelSessionsController < ApplicationController
  def create
    unless valid_patient_phone_number?
      respond_in_plain_text(:create, :bad_request) and return
    end

    session = ExotelSession.new(params[:From], parse_patient_phone_number)
    if session.authorized?
      session.save(params[:CallSid])
      respond_in_plain_text(:create, :ok)
    else
      respond_in_plain_text(:create, :forbidden)
    end
  end

  private

  def parse_patient_phone_number
    params[:digits].tr('"', '')
  end

  def valid_patient_phone_number?
    parse_patient_phone_number.scan(/\D/).empty?
  end

  def report_http_status(api_name, status)
    NewRelic::Agent.increment_metric("ExotelSessions/#{api_name}/#{status.to_s}")
  end

  def respond_in_plain_text(api_name, status)
    report_http_status(api_name, status)
    head status, content_type: 'text/plain'
  end
end
