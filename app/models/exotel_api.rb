class ExotelAPI
  BASE_PATH = 'https://api.exotel.com/v1/Accounts/'
  RESPONSE_FORMAT = '.json'

  def initialize(sid, token)
    @sid = sid
    @token = token
  end

  def call_details(call_sid)
    response = execute(call_details_url(call_sid))
    JSON.parse(response.body[:Call], symbolize_names: true) if response.status.ok?
  rescue HTTP::Error => e
    report_error(:call_details, e)
  end

  def execute(url)
    HTTP
      .basic_auth(user: @sid, pass: @token)
      .get(url)
  end

  private

  def call_details_url(call_sid)
    URI.parse("#{base_uri}/Calls/#{call_sid}#{RESPONSE_FORMAT}")
  end

  def base_uri
    URI.join(BASE_PATH, @sid)
  end

  def report_error(api_name, exception)
    Raven.capture_message(
      'Error while calling the Exotel API',
      logger: 'logger',
      extra: {
        api_name: api_name,
        exception: exception.to_s
      },
      tags: { type: 'exotel-api' })
  end
end
