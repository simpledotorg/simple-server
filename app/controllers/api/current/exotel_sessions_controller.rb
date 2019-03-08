class Api::Current::ExotelSessionsController < ApplicationController
  def passthru
    session = ExotelSession.new(params[:From], parse_digits)

    if session.save(params[:CallSid])
      render plain: "OK", status: 200
    else
      render plain: "NOT OK", status: 403
    end
  end

  def parse_digits
    params[:digits].tr('"', '')
  end
end
