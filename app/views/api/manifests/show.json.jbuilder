# frozen_string_literal: true

json.v1 @countries.each do |country|
  country_config = CountryConfig.for(country)

  json.country_code country_config[:abbreviation]
  json.endpoint "#{ENV["SIMPLE_SERVER_HOST_PROTOCOL"]}://#{ENV["SIMPLE_SERVER_HOST"]}/api/"
  json.display_name country_config[:name]
  json.isd_code country_config[:sms_country_code].tr("+", "")
end
json.v2 do
  json.countries @countries.each do |country|
    country_config = CountryConfig.for(country)
    json.country_code country_config[:abbreviation]
    json.display_name country_config[:name]
    json.isd_code country_config[:sms_country_code].tr("+", "")

    deployments = [country_config[:name]]
    json.deployments(deployments) do |deployment|
      json.display_name deployment
      json.endpoint "#{ENV["SIMPLE_SERVER_HOST_PROTOCOL"]}://#{ENV["SIMPLE_SERVER_HOST"]}/api/"
    end
  end
end
