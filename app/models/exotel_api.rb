class ExotelAPI
  BASE_PATH = 'https://api.exotel.com/v1/Accounts/'
  RESPONSE_FORMAT = '.json'

  def initialize(sid, token)
    @sid = sid
    @token = token
  end

  def call_details(call_sid)
    url = call_details_url(call_sid)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(url)
    req.basic_auth(@sid, @token)
    response = http.request(req)
    JSON.parse(response.body)
  rescue HTTP::Error => e
    report_error(:call_details, e)
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
