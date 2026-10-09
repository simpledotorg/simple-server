json.countries countries do |country|
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
