class ExotelAPI
  BASE_PATH = 'https://api.exotel.com/v1/Accounts/'
  RESPONSE_FORMAT = '.json'

  def initialize(account_sid, token)
    @account_sid = account_sid
    @token = token
  end

  def call_details(call_sid)
    response = execute(call_details_url(call_sid))
    parse_response(response) if response.present?
  end

  private

  def execute(url)
    HTTP
      .basic_auth(user: @account_sid, pass: @token)
      .get(url)
  rescue HTTP::Error => e
    report_error(url, e)
    nil
  end

  def parse_response(response)
    OpenStruct.new(JSON.parse(response,
                              symbolize_names: true)) if response.status.ok?
  end

  def base_uri
    URI.join(BASE_PATH, @account_sid)
  end

  def report_error(api_path, exception)
    Raven.capture_message(
      'Error while calling the Exotel API',
      logger: 'logger',
      extra: {
        api_path: api_path,
        exception: exception.to_s
      },
      tags: { type: 'exotel-api' })
  end

  def call_details_url(call_sid)
    URI.parse("#{base_uri}/Calls/#{call_sid}#{RESPONSE_FORMAT}")
  end
end
