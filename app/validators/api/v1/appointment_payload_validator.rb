class Api::V1::AppointmentPayloadValidator < Api::V2::AppointmentPayloadValidator
  def schema
    Api::V1::Models.appointment
  end
end
