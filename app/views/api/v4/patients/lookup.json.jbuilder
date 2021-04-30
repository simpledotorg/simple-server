json.retention do
  json.type @retention_type
  json.duration_seconds @retention_duration
end

json.patients @patients do |patient|
  json.partial! partial: "api/v4/patient/patient", patient: patient
end
