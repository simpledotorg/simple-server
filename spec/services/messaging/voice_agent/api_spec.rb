require "rails_helper"

RSpec.describe Messaging::VoiceAgent::Api do
  let(:base_url) { "https://voice-agent.example.com" }

  def stub_credentials(url: base_url, api_key: "secret")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("VOICE_AGENT_URL").and_return(url)
    allow(ENV).to receive(:[]).with("VOICE_AGENT_API_KEY").and_return(api_key)
  end

  describe "#new" do
    it "raises an error when the voice agent URL is missing" do
      stub_credentials(url: nil)

      expect { described_class.new }
        .to raise_error(Messaging::VoiceAgent::Error, "Error while calling voice agent API: Missing voice agent URL")
    end

    it "raises an error when the voice agent API key is missing" do
      stub_credentials(api_key: nil)

      expect { described_class.new }
        .to raise_error(Messaging::VoiceAgent::Error, "Error while calling voice agent API: Missing voice agent API key")
    end
  end

  describe "#create_call" do
    let(:payload) { {call_request_id: "abc-123", country: "BD"} }

    it "posts the call request as JSON with a bearer token" do
      stub_credentials
      request = stub_request(:post, "#{base_url}/v1/calls")
        .with(body: payload.to_json,
          headers: {"Content-Type" => "application/json", "Authorization" => "Bearer secret"})
        .to_return(status: 202, body: "")

      described_class.new.create_call(payload)

      expect(request).to have_been_made.once
    end

    it "tolerates a trailing slash on the base URL" do
      stub_credentials(url: "#{base_url}/")
      request = stub_request(:post, "#{base_url}/v1/calls").to_return(status: 202)

      described_class.new.create_call(payload)

      expect(request).to have_been_made.once
    end

    it "raises an error with an invalid_request reason for 4xx responses" do
      stub_credentials
      stub_request(:post, "#{base_url}/v1/calls").to_return(status: 422, body: "bad phone number")

      expect { described_class.new.create_call(payload) }.to raise_error(Messaging::VoiceAgent::Error) { |error|
        expect(error.message).to eq("Error while calling voice agent API: API returned 422 with bad phone number")
        expect(error.reason).to eq(:invalid_request)
      }
    end

    it "raises an error with a server_error reason for 5xx responses" do
      stub_credentials
      stub_request(:post, "#{base_url}/v1/calls").to_return(status: 503, body: "")

      expect { described_class.new.create_call(payload) }.to raise_error(Messaging::VoiceAgent::Error) { |error|
        expect(error.reason).to eq(:server_error)
      }
    end
  end
end
