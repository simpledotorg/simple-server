require "net/http"
require "json"

class Dhis2HttpClient
  class Error < StandardError; end

  class RequestError < Error; end

  class ResponseError < Error; end

  attr_reader :base_url, :username, :password

  def initialize(url:, username:, password:)
    @base_url = url.chomp("/")
    @username = username
    @password = password
  end

  # Bulk create data values in DHIS2
  # @param data_values [Array<Hash>] Array of data value hashes
  # @return [Hash] Parsed response from DHIS2
  # @raise [RequestError] If the HTTP request fails
  # @raise [ResponseError] If DHIS2 returns an error status
  def bulk_create_data_values(data_values:)
    uri = URI("#{@base_url}/api/dataValueSets")
    request = build_request(uri, data_values)

    Rails.logger.info("DHIS2 HTTP Client: Sending #{data_values.count} data values to #{uri}")

    response = execute_request(uri, request)
    parsed_response = parse_response(response)

    Rails.logger.info("DHIS2 HTTP Client: Response status=#{parsed_response[:status]}, imported=#{parsed_response[:imported]}")

    parsed_response
  end

  private

  def build_request(uri, data_values)
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(@username, @password)
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"

    # Transform snake_case keys to camelCase as expected by DHIS2 API
    formatted_data_values = data_values.map { |dv| transform_keys_to_camel_case(dv) }

    request.body = {dataValues: formatted_data_values}.to_json
    request
  end

  def execute_request(uri, request)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.read_timeout = 120 # 2 minutes timeout for large data sets
    http.open_timeout = 30

    begin
      response = http.request(request)

      # Log response for debugging
      Rails.logger.debug("DHIS2 HTTP Response: code=#{response.code}, body=#{response.body[0..500]}")

      response
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise RequestError, "Request timeout: #{e.message}"
    rescue => e
      raise RequestError, "HTTP request failed: #{e.message}"
    end
  end

  def parse_response(response)
    unless response.is_a?(Net::HTTPSuccess)
      error_message = "HTTP #{response.code}: #{response.message}"
      begin
        error_body = JSON.parse(response.body)
        error_message += " - #{error_body["message"]}" if error_body["message"]
      rescue JSON::ParserError
        error_message += " - #{response.body[0..200]}"
      end
      raise ResponseError, error_message
    end

    begin
      body = JSON.parse(response.body, symbolize_names: true)
    rescue JSON::ParserError => e
      raise ResponseError, "Failed to parse JSON response: #{e.message}"
    end

    # DHIS2 can return different response formats depending on version
    # Modern versions return: { status: "SUCCESS", importCount: {...}, ... }
    # Older versions return: { status: "OK", response: {...}, ... }

    status = body[:status] || body.dig(:response, :status)

    # Extract import counts
    import_count = body[:importCount] || body.dig(:response, :importCount) || {}
    imported = import_count[:imported] || 0
    updated = import_count[:updated] || 0
    ignored = import_count[:ignored] || 0
    deleted = import_count[:deleted] || 0

    # Check for conflicts
    conflicts = body[:conflicts] || body.dig(:response, :conflicts) || []

    # Determine if the import was successful
    success = ["SUCCESS", "OK"].include?(status)

    unless success
      conflict_messages = conflicts.map { |c| c[:value] }.join(", ")
      raise ResponseError, "DHIS2 import failed with status '#{status}'. Conflicts: #{conflict_messages}"
    end

    {
      status: status,
      imported: imported,
      updated: updated,
      ignored: ignored,
      deleted: deleted,
      conflicts: conflicts,
      raw_response: body
    }
  end

  # Transform hash keys from snake_case to camelCase
  # Example: { data_element: "X", org_unit: "Y" } => { dataElement: "X", orgUnit: "Y" }
  def transform_keys_to_camel_case(hash)
    hash.transform_keys do |key|
      key.to_s.camelize(:lower).to_sym
    end
  end
end
