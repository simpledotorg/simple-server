module CPHCEnrollment
  FACILITY_TYPE_ID = {
    "PHC" => 3200,
    "CHC" => 3300,
    "DH" => 3400,
    "TERTIARY" => 3500
  }
end

require "tasks/scripts/cphc_enrollment/service"
require "tasks/scripts/cphc_enrollment/request"
require "tasks/scripts/cphc_enrollment/auth_manager"
require "tasks/scripts/cphc_enrollment/blood_pressure_payload"
require "tasks/scripts/cphc_enrollment/blood_sugar_payload"
require "tasks/scripts/cphc_enrollment/hypertension_diagnosis_payload"
require "tasks/scripts/cphc_enrollment/diabetes_diagnosis_payload"
require "tasks/scripts/cphc_enrollment/treatment_payload"
require "tasks/scripts/cphc_enrollment/enrollment_payload"
require "tasks/scripts/cphc_enrollment/prescription_drugs_payload"
require "tasks/scripts/cphc_enrollment/cphc_registry"
