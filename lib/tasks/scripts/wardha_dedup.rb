class WardhaDedup
  def self.discard
    patient_ids = CSV.read("lib/data/wardha_discard.csv")

    Patient.where(id: patient_ids).discard_all
  end

  def self.deduplicate
    rows = CSV.read("lib/data/wardha_deduplicate.csv")

    rows.map do |patient_ids|
      next if Patient.where(id: patient_ids).count < 2

        PatientDeduplication::Runner.new(patient_ids)
    end
  end
end
