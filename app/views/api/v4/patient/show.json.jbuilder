json.patient do
  json.partial! partial: "api/v4/patient/patient", patient: @current_patient
end
