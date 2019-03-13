class ExotelSession
  KEY = 'EXOTEL-SESSION'

  def initialize(user_phone_number, patient_phone_number)
    @user = User.find_by_phone_number(user_phone_number)
    @patient_phone_number = PatientPhoneNumber.find_by_number(patient_phone_number)
  end

  def save(call_id)
    Rails.cache.write(session_key(call_id), record)
  end

  def authorized?
    @user.present? &&
      @patient_phone_number.present? &&
      @user.phone_number != @patient_phone_number.number
  end

  private

  def session_key(call_id)
    KEY + '-' + call_id
  end

  def record
    { patient_phone_number: @patient_phone_number.number,
      user_phone_number: @user.phone_number }
  end
end

