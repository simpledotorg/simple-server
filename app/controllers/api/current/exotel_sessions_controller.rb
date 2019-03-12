class Api::Current::ExotelSessionsController < ApplicationController
  def passthru
    session = ExotelSession.new(params[:From], parse_digits)

    if session.save(params[:CallSid])
      respond_in_plain_text(:ok)
    else
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
end
