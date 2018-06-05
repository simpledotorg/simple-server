require File.expand_path('spec/utils')

HOST = 'http://localhost:3000'.freeze

def post(path, request_body)
  uri          = URI.parse(HOST + path)
  header       = { 'Content-Type' => 'application/json',
                   'ACCEPT'       => 'application/json' }
  http         = Net::HTTP.new(uri.host, uri.port)
  request      = Net::HTTP::Post.new(uri.request_uri, header)
  request.body = request_body.to_json
  response     = http.request(request)
  print response.body
end

def get(path, query_params = {})
  uri       = URI.parse(HOST + path)
  uri.query = URI.encode_www_form(query_params)
  header    = { 'Content-Type' => 'application/json',
                'ACCEPT'       => 'application/json' }
  http      = Net::HTTP.new(uri.host, uri.port)
  request   = Net::HTTP::Get.new(uri.request_uri, header)
  response  = http.request(request)
  print JSON.pretty_generate(JSON(response.body))
end

def log(msg)
  puts "\n"
  puts '=' * 20
  puts msg
  puts '=' * 20
  puts "\n"
end

def create_patients
  log 'creating 10 patients'
  post '/api/v1/patients/sync', patients: (1..10).map { build_patient_payload }
end

def create_invalid_patients
  log 'creating 10 invalid patients'
  post '/api/v1/patients/sync', patients: (1..10).map { build_invalid_patient_payload }
end

def get_patients
  log 'getting all patients'
  get '/api/v1/patients/sync', limit: 100_000
end

def create_bps
  log 'creating 10 BPs'
  post '/api/v1/blood_pressures/sync', blood_pressures: (1..10).map { build_blood_pressure_payload }
end

def create_invalid_bps
  log 'creating 10 invalid BPs'
  post '/api/v1/blood_pressures/sync', blood_pressures: (1..10).map { build_invalid_blood_pressure_payload }
end

def get_bps
  log 'getting all BPs'
  get '/api/v1/blood_pressures/sync', limit: 100_000
end


create_patients
create_invalid_patients
get_patients

create_bps
create_invalid_bps
get_bps