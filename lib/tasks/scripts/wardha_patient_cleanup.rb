class WardhaPatientCleanup
  def self.discard
    patient_ids = CSV.read("lib/data/wardha_discard_patients.csv")

    Patient.where(id: patient_ids).discard_all
  end

  def self.deduplicate
    rows = CSV.read("lib/data/wardha_deduplicate_patients.csv")

    rows.map do |patient_ids|
      next if Patient.where(id: patient_ids).count < 2

      PatientDeduplication::Runner.new(patient_ids)
    end
  end
end
