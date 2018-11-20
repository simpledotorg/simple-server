module Api::V1::ApiControllerOverrides
  def current_facility
    nil
  end

  def validate_facility
    true
  end
end
