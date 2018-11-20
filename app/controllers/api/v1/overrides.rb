module Api::V1::Overrides
  def current_facility
    nil
  end

  def validate_facility
    true
  end
end
