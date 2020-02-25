#
# The purpose of this script is to ensure that the exported data passes all schema validation checks
#
# This is a very low-cost way of ensuring your imported data is correct, so go through the comments down below to
# learn how to use and run this script
#
# NOTE: How to run
#
# In a rails console,
#
# > require './lib/bangladesh/validate_data.rb'
# > ValidateData.new.validate
#
require 'http'

class ValidateData
  #
  # NOTE: Modify this URL as per your env
  #
  HOST = 'http://simple.test'.freeze

  REQUEST_URLS = [
    :patients,
    :blood_pressures,
    :blood_sugars,
    :appointments,
    :medical_histories,
    :prescription_drugs
  ].freeze

  def validate
    REQUEST_URLS.each do |model|
      api_get(model)
    end
  end

  #
  # NOTE: Modify the Bearer token as per your user's access_token
  #
  def api_get(model_name)
    response = HTTP
                 .auth('Bearer 72789892ff8f876e159e7757983ff82f60b37d3e5a84240e61470c85eecaa50f')
                 .headers(api_headers)
                 .get(api_url("api/v3/#{model_name}/sync"))

    validator = "Api::Current::#{model_name.to_s.classify}PayloadValidator".constantize
    response_body = JSON(response.body)

    response_body[model_name.to_s].each do |res|
      v = validator.new(res.except('deleted_at'))
      if v.invalid?
        puts v.errors.full_messages
      end
    end
  end

  #
  # NOTE: Modify the user and facility ID headers as per your test
  #
  def api_headers
    { 'Content-Type' => 'application/json',
      'ACCEPT' => 'application/json',
      'X-USER-ID' => '60cae40c-3364-402f-8bbd-285d65150dcf',
      'X-FACILITY-ID' => 'b4c5d96a-a02b-41ef-96d7-7a6eddda4c85' }
  end

  def api_url(path)
    URI.parse("#{HOST}/#{path}")
  end
end
