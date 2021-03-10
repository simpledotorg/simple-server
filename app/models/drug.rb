class Drug < ActiveYaml::Base
  set_root_path "config/data"
  set_filename "drugs"

  CREATED_TIME ||= File.ctime("config/data/drugs.yml").in_time_zone("UTC")
  UPDATED_TIME ||= File.mtime("config/data/drugs.yml").in_time_zone("UTC")

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
    once_a_day: "Once a day",
    twice_a_day: "Twice a day",
    thrice_a_day: "Thrice a day"
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
