class ExotelAPIService
  BASE_PATH = "https://api.exotel.com/v1/Accounts/"
  RESPONSE_FORMAT = ".json"

  EXOTEL_TRUTHY_STRINGS = ["Yes"]

  attr_reader :account_sid, :token

  class ExotelAPIService::HTTPError < HTTP::Error
  end

  def initialize(account_sid, token)
    @account_sid = account_sid
    @token = token
  end

  def call_details(call_sid)
    response = execute_get(call_details_url(call_sid))
    parse_response(response) if response.present?
  end

  def whitelist_phone_numbers(virtual_number, phone_numbers)
    return unless FeatureToggle.enabled?("EXOTEL_WHITELIST_API")

    request_body = {
      Language: "en",
      VirtualNumber: virtual_number,
      Number: phone_numbers.join(",")
    }

    execute_post(whitelist_phone_numbers_url, form: request_body)
  end

  def phone_number_details(phone_number)
    phone_number_details_response = execute_get(phone_number_details_url(phone_number))
    whitelist_details_response = execute_get(whitelist_details_url(phone_number))

    phone_number_details = parse_response(phone_number_details_response) || {}
    whitelist_details = parse_response(whitelist_details_response) || {}
    {
      dnd_status: EXOTEL_TRUTHY_STRINGS.include?(phone_number_details.dig(:Numbers, :DND)),
      phone_type: parse_response_field(phone_number_details.dig(:Numbers, :Type), :invalid),
      whitelist_status: parse_response_field(whitelist_details.dig(:Result, :Status), nil),
      whitelist_status_valid_until: parse_exotel_whitelist_expiry(whitelist_details.dig(:Result, :Expiry))
    }
  end

  def parse_exotel_whitelist_expiry(expiry_time)
    return if expiry_time.blank? || expiry_time < 0
    Time.current + expiry_time.seconds
  end

  private

  def parse_response_field(field, default)
    return default if field.blank?
    field.downcase.to_sym
  end

  def execute_get(url)
    HTTP
      .basic_auth(user: account_sid, pass: token)
      .get(url)
  rescue HTTP::Error => e
    report_error(url, e)
    raise ExotelAPIService::HTTPError
  end

  def execute_post(url, data)
    HTTP
      .basic_auth(user: account_sid, pass: token)
      .post(url, data)
  rescue HTTP::Error => e
    report_error(url, e)
    raise ExotelAPIService::HTTPError
  end

  def parse_response(response)
    return unless response.status.ok?

    response.parse(:json).deep_symbolize_keys
  end

  def base_uri
    URI.join(BASE_PATH, account_sid)
  end

  def report_error(api_path, exception)
    Sentry.capture_message(
      "Error while calling the Exotel API",
      extra: {
        api_path: api_path,
        exception: exception.to_s
      },
      tags: {type: "exotel-api"}
    )
  end

  def call_details_url(call_sid)
    URI.parse("#{base_uri}/Calls/#{call_sid}#{RESPONSE_FORMAT}")
  end

  def whitelist_phone_numbers_url
    URI.parse("#{base_uri}/CustomerWhitelist#{RESPONSE_FORMAT}")
  end

  def phone_number_details_url(phone_number)
    URI.parse("#{base_uri}/Numbers/#{ERB::Util.url_encode(phone_number)}#{RESPONSE_FORMAT}")
  end

  def whitelist_details_url(phone_number)
    URI.parse("#{base_uri}/CustomerWhitelist/#{ERB::Util.url_encode(phone_number)}#{RESPONSE_FORMAT}")
  end
end
