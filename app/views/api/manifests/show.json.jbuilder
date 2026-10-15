json.v1 @countries.each do |country|
  country_config = CountryConfig.for(country)

  json.country_code country_config[:abbreviation]
  json.endpoint "#{ENV["SIMPLE_SERVER_HOST_PROTOCOL"]}://#{ENV["SIMPLE_SERVER_HOST"]}/api/"
  json.display_name country_config[:name]
  json.isd_code country_config[:sms_country_code].tr("+", "")
end
json.v2 do
  json.partial! "api/manifests/countries", countries: @countries
end

# Current Simple Android builds read this format (the same as manifest.simple.org)
json.version "3"
json.partial! "api/manifests/countries", countries: @countries
