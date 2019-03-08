class Api::Current::ExotelSessionsController < ApplicationController
  def passthru
    session = ExotelSession.new(params[:From], params[:digits])

    if session.pass_thru_available?
      session.save(params[:CallSid])
      respond_to do |format|
        format.text { session.patient_phone_number.to_s }
      end
    else
      respond_to do |format|
        format.text { '403' }
      end
    end
  end

  def connect
    session = ExotelSession.find(params[:CallSid])

    if session.present?
      respond_to do |format|
        format.text { session.patient_phone_number.to_s }
      end
    else
      render status: 403
    end
  end
end
