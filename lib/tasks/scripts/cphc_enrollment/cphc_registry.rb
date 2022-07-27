class CPHCEnrollment::CPHCRegistry
  attr_reader :registry

  def initialize
    @registry = {}
  end

  def add(key, simple_id, cphc_id)
    registry[key] ||= {}
    registry[key][simple_id] = cphc_id
  end

  def find_cphc_id(key, simple_id)
    registry.dig(key, simple_id)
  end

  def find_or_add(key, simple_id, cphc_id)
    find_cphc_id(key, simple_id) || add(key, simple_id, cphc_id)
  end
end
