METHODS_TO_INSTRUMENT = [
  [Api::Current::PatientTransformer.singleton_class, :from_nested_request],
  [Api::Current::PatientTransformer.singleton_class, :to_nested_response],

  [Api::Current::BloodPressureTransformer.singleton_class, :from_request],
  [Api::Current::BloodPressureTransformer.singleton_class, :to_response],

  [Api::Current::PatientsController, :current_facility_records],
  [Api::Current::PatientsController, :other_facility_records],

  [Api::Current::BloodPressuresController, :current_facility_records],
  [Api::Current::BloodPressuresController, :other_facility_records],

  [MergePatientService, :merge]
]

METHODS_TO_INSTRUMENT.each do |class_method|
  cls = class_method[0]
  method = class_method[1]

  cls.class_eval do
    include ::NewRelic::Agent::MethodTracer
    add_method_tracer method
  end
end