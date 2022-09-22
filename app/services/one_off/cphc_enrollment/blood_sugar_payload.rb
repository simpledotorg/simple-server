class OneOff::CPHCEnrollment::BloodSugarPayload
  attr_reader :blood_sugar

  def initialize(blood_sugar)
    @blood_sugar = blood_sugar
  end

  def as_json
    {
      isVitalsEdited: true,
      exam: {
        assessDate: blood_sugar.recorded_at.strftime("%d-%m-%Y")
      }.merge(blood_sugar_type_payload)
    }
  end

  def blood_sugar_type_payload
    value = blood_sugar.blood_sugar_value
    case blood_sugar.blood_sugar_type.to_sym
    when :random
      {"rbs" => value.to_i,
       :mthdOfBldTstRbsCapillaryVenous => "rbgCapillary"}
    when :post_prandial
      {"ppbg" => value.to_i,
       :mthdOfBldTstPpbgCapillaryVenous => "ppbgCapillary"}
    when :fasting
      {"fbs" => value.to_s}
    when :hba1c
      {"hba1c" => value.to_s}
    else
      throw "Unknown blood sugar type #{blood_sugar.blood_sugar_type}"
    end
  end
end
