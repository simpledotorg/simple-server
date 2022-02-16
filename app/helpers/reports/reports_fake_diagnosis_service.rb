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
      @hypertension_registered_patients = {
        "name" => "Total registered patients",
        "subtitle" => "All hypertensive patients registered in #{facility_name}",
        "breakdown" => [
          {"month" => "Aug-2021", "value" => 187},
          {"month" => "Sep-2021", "value" => 320},
          {"month" => "Oct-2021", "value" => 498},
          {"month" => "Nov-2021", "value" => 570},
          {"month" => "Dec-2021", "value" => 634},
          {"month" => "Jan-2022", "value" => 877}
        ]
      }
    end

    def call
      {
        "hypertension_assigned_patients" => @hypertension_assigned_patients,
        "hypertension_registered_patients" => @hypertension_registered_patients
      }
    end
  end
end