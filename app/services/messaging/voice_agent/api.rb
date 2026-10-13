class Messaging::VoiceAgent::Api
  CALLS_PATH = "/v1/calls"
  OPEN_TIMEOUT_SECONDS = 10
  READ_TIMEOUT_SECONDS = 30

  def initialize
    raise Messaging::VoiceAgent::Error.new("Missing voice agent URL") if base_url.blank?
    raise Messaging::VoiceAgent::Error.new("Missing voice agent API key") if api_key.blank?
  end

  # The voice agent queues the call and responds with 202. It treats a repeated
  # call_request_id as a duplicate and accepts it again without dialing twice.
  def create_call(payload)
    post(CALLS_PATH, payload)
  end

  private

  def base_url
    ENV["VOICE_AGENT_URL"]
  end

  def api_key
    ENV["VOICE_AGENT_API_KEY"]
  end

  def post(path, body)
    uri = URI("#{base_url.chomp("/")}#{path}")
    request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json", "Authorization" => "Bearer #{api_key}")
    request.body = body.to_json

    response = Net::HTTP.start(uri.hostname, uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: OPEN_TIMEOUT_SECONDS,
      read_timeout: READ_TIMEOUT_SECONDS) { |http| http.request(request) }

    unless response.is_a?(Net::HTTPSuccess)
      raise Messaging::VoiceAgent::Error.new(
        "API returned #{response.code} with #{response.body}",
        reason: response.is_a?(Net::HTTPClientError) ? :invalid_request : :server_error
      )
    end

    response
  end
end
