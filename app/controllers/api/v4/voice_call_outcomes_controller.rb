class Api::V4::VoiceCallOutcomesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action -> { doorkeeper_authorize! :voice_agent }

  # The voice agent retries delivery until it gets a 2xx, so a repeated
  # call_request_id is acknowledged with 200 and ignored.
  def create
    voice_call_detail = VoiceCallDetail.find_by(call_request_id: outcome_params[:call_request_id])
    return head :not_found unless voice_call_detail

    outcome = VoiceAgent::Outcome.new(outcome_params)
    unless outcome.valid?
      log_failure(outcome.errors.to_hash)
      return render json: {errors: outcome.errors.to_hash}, status: :unprocessable_entity
    end

    result = VoiceAgent::OutcomeApplier.call(voice_call_detail, outcome)
    render json: {result: result}, status: :ok
  end

  private

  def outcome_params
    params.permit(
      :call_request_id,
      :status,
      :outcome,
      :suggested_remove_reason,
      :safety_flag,
      :confidence,
      :attempts,
      :answered_attempts,
      :last_attempted_at,
      :connected_seconds,
      :provider,
      :prompt_version
    ).to_h
  end

  def log_failure(errors)
    Rails.logger.info(
      msg: "voice_call_outcome_error",
      controller: self.class.name,
      action: action_name,
      call_request_id: outcome_params[:call_request_id],
      errors: errors
    )
  end
end
