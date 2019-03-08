class ExotelSession
  KEY = 'EXOTEL-SESSION'

  def initialize(user_phone_number, patient_phone_number)
    @user_phone_number = user_phone_number
    @patient_phone_number = patient_phone_number
  end

  def save(call_id)
    if passthru?
      record = { patient_phone_number: @patient_phone_number,
                 user_phone_number: @user_phone_number }

      Rails.cache.write(KEY + call_id, record)
    end
  end

  private

  def passthru?
    User.find_by_phone_number(@user_phone_number).present? &&
      PatientPhoneNumber.find_by_number(@patient_phone_number).present?
  end
end
