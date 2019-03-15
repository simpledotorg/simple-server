class CallSession
  EXPIRE_CALL_SESSION_IN = 24.hours

  attr_reader :patient_phone_number, :user

  def initialize(call_id, user_phone_number, patient_phone_number)
    @call_id = call_id
    @user = User.find_by_phone_number(sanitized_phone_number(user_phone_number))
    @patient_phone_number = PatientPhoneNumber.find_by_number(patient_phone_number)
  end

  def authorized?
    @user.present? &&
      patient_phone_number.present? &&
      @user.phone_number != patient_phone_number.number
  end

  def save
    Rails.cache.write(CallSession.session_key(@call_id),
                      session_data,
                      expires_in: EXPIRE_CALL_SESSION_IN)
  end

  def kill
    Rails.cache.delete(CallSession.session_key(@call_id))
  end

  class << self
    def fetch(call_id)
      data = Rails.cache.fetch(session_key(call_id))

      CallSession.new(call_id,
                      data[:user_phone_number],
                      data[:patient_phone_number]) if data.present?
    end

    def session_key(call_id)
      [name, call_id].join('/')
    end
  end

  private

  def sanitized_phone_number(phone_number)
    Phonelib.parse(phone_number, 'IN').raw_national
  end

  def session_data
    { patient_phone_number: patient_phone_number.number,
      user_phone_number: user.phone_number }
  end
end
