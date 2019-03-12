class ExotelSession
  KEY = 'EXOTEL-SESSION'
  STATUSES = {
    passthru: 'passthru',
  }

  def initialize(user_phone_number, patient_phone_number)
    @user = User.find_by_phone_number(user_phone_number)
    @patient_phone_number = PatientPhoneNumber.find_by_number(patient_phone_number)
    @status_log = []
  end

  def save(call_id)
    Rails.cache.write(session_key(call_id), record)
  end

  def passthru?
    @user.present? && @patient_phone_number.present?
  end

  def update_status_log(new_status)
    @status_log << new_status
  end

  private

  def session_key(call_id)
    [KEY, @user.id, call_id].join('-')
  end

  def record
    { patient_phone_number: @patient_phone_number.number,
      status_log: @status_log,
      user_phone_number: @user.phone_number }
  end
end
