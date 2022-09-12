class CPHCEnrollment::CPHCRegistry
  attr_reader :registry

  def initialize
    @registry = {}
  end

  def update(patient_id, updates)
    hash = @registry[patient_id] || {}
    @registry[patient_id] = hash.merge(updates)
  end

  def get(patient_id, keys)
    throw "Patient: #{patient_id} not found in the registry" unless @registry[patient_id]
    @registry[patient_id].dig(*keys)
  end
end
