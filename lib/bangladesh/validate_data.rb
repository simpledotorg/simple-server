require 'http'

class ValidateData

  HOST = "http://simple.test"

  REQUEST_URLS = [
    :patients,
    :blood_pressures,
    :blood_sugars,
    :appointments,
    :medical_histories,
    :prescription_drugs,
  ]

  def validate
    REQUEST_URLS.each do |model|
      api_get(model)
    end
  end

  def api_get(model_name)
    response = HTTP
                 .auth("Bearer 72789892ff8f876e159e7757983ff82f60b37d3e5a84240e61470c85eecaa50f")
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

  def api_headers
    { 'Content-Type' => 'application/json',
      'ACCEPT' => 'application/json',
      'X-USER-ID' => '60cae40c-3364-402f-8bbd-285d65150dcf',
      'X-FACILITY-ID' => 'b4c5d96a-a02b-41ef-96d7-7a6eddda4c85'
    }
  end

  def api_url(path)
    URI.parse("#{HOST}/#{path}")
  end
end
