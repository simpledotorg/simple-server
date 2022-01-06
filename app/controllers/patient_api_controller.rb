# frozen_string_literal: true

class PatientAPIController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :validate_current_patient
  before_action :authenticate

  rescue_from ActionController::ParameterMissing do
    head :bad_request
  end

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  private

  def access_token_authorized?
    authenticate_with_http_token do |token, _options|
      current_patient.access_tokens.any? do |patient_token|
        ActiveSupport::SecurityUtils.secure_compare(token, patient_token)
      end
    end
  end

  def authenticate
    return head :unauthorized unless access_token_authorized?
  end

  def current_patient
    @current_patient ||= Patient.find_by(id: request.headers["HTTP_X_PATIENT_ID"])
  end

  def validate_current_patient
    return head :unauthorized unless current_patient.present?
  end
end
