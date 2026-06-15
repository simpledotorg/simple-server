# frozen_string_literal: true

require "http"

module Dhis2
  class Error < StandardError; end

  class RequestError < Error
    attr_reader :response

    def initialize(message, response: nil)
      super(message)
      @response = response
    end
  end

  class ImportError < Error
    attr_reader :response

    def initialize(message, response:)
      super(message)
      @response = response
    end
  end

  class DataValueSetsClient
    DEFAULT_TIMEOUT_SECONDS = 120

    def self.from_env
      new(
        url: ENV.fetch("DHIS2_URL"),
        username: ENV.fetch("DHIS2_USERNAME"),
        password: ENV.fetch("DHIS2_PASSWORD"),
        timeout: ENV.fetch("DHIS2_TIMEOUT_SECONDS", DEFAULT_TIMEOUT_SECONDS).to_i
      )
    end

    def initialize(url:, username:, password:, timeout: DEFAULT_TIMEOUT_SECONDS)
      @url = url
      @username = username
      @password = password
      @timeout = timeout
    end

    def bulk_create(data_values:)
      response = request.post(data_value_sets_url, json: payload(data_values))
      parsed_response = parse_response(response)
      raise RequestError.new(error_message(response, parsed_response), response: response) unless response.status.success?
      raise ImportError.new("DHIS2 import failed: #{parsed_response}", response: parsed_response) unless import_success?(parsed_response)

      parsed_response
    rescue HTTP::Error, OpenSSL::SSL::SSLError, SocketError => error
      raise RequestError, "DHIS2 request failed: #{error.message}"
    end

    private

    attr_reader :url, :username, :password, :timeout

    def request
      HTTP.basic_auth(user: username, pass: password)
        .timeout(connect: timeout, write: timeout, read: timeout)
        .headers(accept: "application/json")
    end

    def data_value_sets_url
      "#{url.chomp("/")}/api/dataValueSets"
    end

    def payload(data_values)
      {dataValues: data_values.map { |data_value| payload_data_value(data_value) }}
    end

    def payload_data_value(data_value)
      {
        dataElement: data_value.fetch(:data_element),
        orgUnit: data_value.fetch(:org_unit),
        period: data_value.fetch(:period),
        value: data_value.fetch(:value)
      }.tap do |payload|
        payload[:categoryOptionCombo] = data_value[:category_option_combo] if data_value.key?(:category_option_combo)
        payload[:attributeOptionCombo] = data_value[:attribute_option_combo] if data_value.key?(:attribute_option_combo)
      end
    end

    def parse_response(response)
      return {} if response.body.to_s.blank?

      JSON.parse(response.body.to_s)
    rescue JSON::ParserError
      raise RequestError.new("DHIS2 returned invalid JSON: #{response.body}", response: response)
    end

    def import_success?(response)
      summary = response.fetch("response", response)
      import_count = summary["importCount"] || summary["import_count"]
      status = summary["status"] || response["status"]

      %w[OK SUCCESS].include?(status) && import_count.present? && import_count.fetch("ignored", 0).zero?
    end

    def error_message(response, parsed_response)
      "DHIS2 request failed with HTTP #{response.status.code}: #{parsed_response}"
    end
  end
end
