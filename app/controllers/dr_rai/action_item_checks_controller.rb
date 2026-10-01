class DrRai::ActionItemChecksController < AdminController
  before_action :authorize_user

  EVALUATE_URL = "https://ai-gateway.vercel.sh/v1/evaluate"
  ACTIONABLE_INSTRUCTIONS = <<~TEXT.squish
    This is a clear action that a nurse, doctor or facility manager at a health facility
    could personally carry out. It says what to do, not just an outcome, a statistic,
    or a task for someone outside the facility (e.g. a call centre).
  TEXT

  def create
    body = params[:body].to_s.strip
    if body.blank? || ENV["AI_GATEWAY_API_KEY"].blank?
      render json: {error: "Couldn't check this task"}, status: :unprocessable_entity
      return
    end

    probability = evaluate_actionable(body)
    if probability.nil?
      render json: {error: "Couldn't check this task"}, status: :bad_gateway
    else
      render json: {probability: probability}
    end
  end

  private

  def authorize_user
    authorize { current_admin.accessible_facilities(:view_reports).any? }
  end

  def evaluate_actionable(body)
    uri = URI(EVALUATE_URL)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{ENV["AI_GATEWAY_API_KEY"]}"
    request["Content-Type"] = "application/json"
    request.body = {
      model: "typesafe-ai/jev",
      state: {item: body},
      questions: {
        actionable: {
          type: "boolean",
          instructions: ACTIONABLE_INSTRUCTIONS
        }
      }
    }.to_json

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).dig("answers", "actionable", "probability")
  rescue JSON::ParserError, SocketError, SystemCallError, Timeout::Error, Net::HTTPError
    nil
  end
end
