class CPHCEnrollment::BloodSugarPayload
  attr_reader :blood_sugar

  def initialize(blood_sugar)
    @blood_sugar = blood_sugar
  end

  def as_json
    sugar_vitals = {
      assesDate: blood_sugar.recorded_at.strftime("%d-%m-%Y"),
      # TODO: Adding these by default for now
    }

    {
      vitalsDate: blood_sugar.recorded_at,
      sugarVitals: sugar_vitals.merge(blood_sugar_type_payload)
    }
  end

  def blood_sugar_type_payload
    value = blood_sugar.blood_sugar_value
    case blood_sugar.blood_sugar_type.to_sym
    when :random
      {"rndBldGlc" => value.to_i ,
       :mthdOfBldTstRbsCapillaryVenous => "rbgCapillary"}
    when :post_prandial
      {"postPradBldGlc" => value.to_i,
       :mthdOfBldTstPpbgCapillaryVenous => "ppbgCapillary"}
    when :fasting
      {"fastngBldGlc" => value.to_i}
    when :hba1c
      {"hba1c" => value.to_f}
    else
      throw "Unknown blood sugar type #{blood_sugar.blood_sugar_type}"
    end
  end
end
