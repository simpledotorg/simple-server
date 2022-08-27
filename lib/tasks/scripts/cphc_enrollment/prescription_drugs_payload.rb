class CPHCEnrollment::PrescriptionDrugsPayload
  attr_reader :prescription_drugs

  def initialize(prescription_drugs)
    @prescription_drugs = prescription_drugs
  end

  def as_json
    medicines = prescription_drugs.map do |prescription_drug|
      {
        conditn: condition,
        name: prescription_drug.name,
        freq: frequency,
        quan: 30,
        date: prescription_drug.device_created_at,
        duratn: 30
      }
    end

    {assesDate: Date.today,
     medicines: medicines}
  end

  def condition
    "Hypertension"
  end

  def frequency
    "Once a day"
  end
end
