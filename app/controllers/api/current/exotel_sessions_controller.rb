class Api::Current::ExotelSessionsController < ApplicationController
  def passthru
    session = ExotelSession.new(params[:From], parse_digits)

    if session.passthru?
      session.update_status_log(ExotelSession::STATUSES[:passthru])
      session.save(params[:CallSid])
      report_status(ExotelSession::STATUSES[:passthru], :ok)
      respond_in_plain_text(:ok)
    else
      report_status(ExotelSession::STATUSES[:passthru], :forbidden)
      respond_in_plain_text(:forbidden)
    end
  end

  private

  def parse_digits
    params[:digits].tr('"', '')
  end

  def respond_in_plain_text(status)
    head status, content_type: 'text/plain'
  end

  def report_status(api_name, status)
    NewRelic::Agent.increment_metric("ExotelSessions/#{api_name}/#{status.to_s}")
  end
end
