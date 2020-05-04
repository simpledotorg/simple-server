class SetRiskLevel
  Result = Struct.new(:updates, :no_changes, keyword_init: true)

  def self.call(patients)
    result = Result.new(updates: 0, no_changes: 0)
    Array(patients).each do |patient|
      new_level = patient.risk_priority
      if patient.risk_level != new_level
        patient.update(risk_level: new_level)
        result[:updates] += 1
      else
        result[:no_changes] += 1
      end
    end
    result
  end

end
