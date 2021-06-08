module Experimentation
  class DataExport

    HEADERS = ["Test", "Bucket", "Bucket name", "Experiment Inclusion Date", "Appointment Creation Date",
      	"Appointment Date",	"Patient Visit Date",	"Days to visit", "Message 1 Type", "Message 1 Sent", "Message 1 Received", "Message 2 Type", "Message 2 Sent",
        "Message 2 Status",	"Message 3 Type",	"Message 3 Sent",	"Message 3 Received",	"BP recorded at visit",	"Patient Gender",	"Patient Age",
        "Patient risk level",	"Diagnosed HTN", "Patient has phone number", "Patient Visited Facility", "Visited Facility Type",	"Visited Facility State",
        "Visited Facility District", "Visited Facility Block", "Patient Assigned Facility",	"Assigned Facility Type",	"Assigned Facility State",
        "Assigned Facility District", "Assigned Facility Block", "Prior visit 1",	"Prior visit 2", "Prior visit 12", "Call made 1",	"Call made 2",
        "Call made 3", "Patient registration date",	"Patient ID"]

    attr_reader :experiment

    def initialize(name)
      @experiment = Experimentation::Experiment.find_by!(name: name)
    end

    def result
      query.values
    end

    private
    def query
      GitHub::SQL.new(<<~SQL, parameters)
        WITH experiment_subjects AS (
          SELECT patients.id AS patient_id, patients.gender AS gender, treatment_groups.id AS treatment_group_id,
          treatment_groups.description AS treatment_group_description
          FROM patients
          INNER JOIN treatment_group_memberships ON treatment_group_memberships.patient_id = patients.id
          INNER JOIN treatment_groups ON treatment_groups.id = treatment_group_memberships.treatment_group_id
          INNER JOIN experiments ON experiments.id = treatment_groups.experiment_id
          WHERE experiments.id = :experiment_id
        )
        SELECT
          experiment_subjects.patient_id,
          experiment_subjects.gender,
          experiment_subjects.treatment_group_id,
          experiment_subjects.treatment_group_description
        FROM experiment_subjects
      SQL
    end

    def parameters
      {
        experiment_id: experiment.id,
        experiment_start: experiment.start_date.in_time_zone(Rails.application.config.country[:time_zone]).beginning_of_day,
        experiment_end: experiment.end_date.in_time_zone(Rails.application.config.country[:time_zone]).end_of_day
      }
    end

  end
end