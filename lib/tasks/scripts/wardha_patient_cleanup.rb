class WardhaPatientCleanup
  def self.discard
    patient_ids = CSV.read("lib/data/wardha_discard_patients.csv").map(&:first).map(&:strip)

    ActiveRecord::Base.transaction do
      Patient.where(id: patient_ids).each(&:discard_data)
    end
  end

  def self.deduplicate
    rows = CSV.read("lib/data/wardha_deduplicate_patients.csv")

    rows.each do |patient_ids|
      patient_ids = patient_ids.map(&:strip)
      next if Patient.where(id: patient_ids).count < 2

      PatientDeduplication::Runner.new([patient_ids]).perform
    end
  end
end
