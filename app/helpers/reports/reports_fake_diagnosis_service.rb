module Reports
  class ReportsFakeDiagnosisService
    def initialize(facility_name)
      @hypertension_assigned_patients = {
        "name" => "Assigned patients",
        "total" => 793,
        "subtitle" => "Patients expected to follow-up at #{facility_name} to receive hypertension treatment.",
        "breakdown" => [
          {"title" => "Registered patients", "value" => 877},
          {"title" => "Transferred-in", "value" => 3},
          {"title" => "Transferred-out", "value" => -87}
        ]
      }
    end

    def call
      {
        "hypertension_assigned_patients" => @hypertension_assigned_patients
      }
    end
  end
end