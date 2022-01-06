# frozen_string_literal: true

class Medication < ActiveYaml::Base
  set_root_path "config/data"
  set_filename "medications"

  CREATED_TIME = File.ctime("config/data/medications.yml").in_time_zone("UTC")
  UPDATED_TIME = File.mtime("config/data/medications.yml").in_time_zone("UTC")

  CATEGORIES = {
    hypertension_ccb: "Hypertension: CCB",
    hypertension_arb: "Hypertension: ARB",
    hypertension_diuretic: "Hypertension: Diuretic",
    hypertension_ace: "Hypertension: ACE Inhibitor",
    hypertension_other: "Hypertension: Other",
    diabetes: "Diabetes",
    other: "Other"
  }.freeze

  FREQUENCIES = {
    one_per_day: "One per day",
    two_per_day: "Two per day",
    three_per_day: "Three per day",
    four_per_day: "Four per day"
  }.freeze

  def updated_at
    UPDATED_TIME
  end

  def created_at
    CREATED_TIME
  end

  def deleted_at
    if deleted == true
      UPDATED_TIME
    end
  end
end
