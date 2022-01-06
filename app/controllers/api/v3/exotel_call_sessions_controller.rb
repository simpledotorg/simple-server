# frozen_string_literal: true

class Api::V3::ExotelCallSessionsController < ApplicationController
  SCHEDULE_CALL_LOG_JOB_AFTER = 30.minutes

  def create
    unless valid_patient_phone_number?
      respond_in_plain_text(:bad_request) && return
    end

    session = CallSession.new(params[:CallSid], params[:From], parse_patient_phone_number)
    if session.authorized?
      session.save
      respond_in_plain_text(:ok)
    else
      respond_in_plain_text(:forbidden)
    end
  end

  def fetch
    session = CallSession.fetch(params[:CallSid])

    if session.present?
      respond_in_plain_text(:ok, session.patient_phone_number.number)
    else
      respond_in_plain_text(:not_found)
    end
  end

  def terminate
    session = CallSession.fetch(params[:CallSid])

    if session.present?
      session.kill

      report_call_info
      schedule_call_log_job(session.user_phone_number, session.patient_phone_number.number)

      respond_in_plain_text(:ok)
    else
      respond_in_plain_text(:not_found)
    end
  end

  private

  def call_status
    status = params[:CallStatus] || params[:DialCallStatus]

    if status.blank? || status == "null"
      CallLog.results[:unknown]
    else
      status.underscore
    end
  end

  def call_type
    params[:CallType].underscore
  end

  def parse_patient_phone_number
    params[:digits].tr('"', "")
  end

  def valid_patient_phone_number?
    parse_patient_phone_number.scan(/\D/).empty?
  end

  def respond_in_plain_text(status, text = "")
    render plain: text, status: status
  end

  def report_call_info
    Statsd.instance.increment("#{controller_name}.call_type.#{call_type}")
    Statsd.instance.increment("#{controller_name}.call_status.#{call_status}")
  end

  def schedule_call_log_job(user_phone_number, callee_phone_number)
    ExotelCallDetailsJob
      .set(wait: SCHEDULE_CALL_LOG_JOB_AFTER)
      .perform_later(params[:CallSid],
        user_phone_number,
        callee_phone_number,
        call_status)
  end
end
