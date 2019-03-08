class ExotelSession
  KEY = 'EXOTEL-SESSION'

  attr_accessor :patient_phone_number

  def initialize(user_phone_number, patient_phone_number)
    @user_phone_number = user_phone_number
    @patient_phone_number = patient_phone_number
  end

  def self.find(call_id)
    record = Rails.cache.fetch(KEY + call_id)

    if record.present?
      ExotelSession.new(record[:user_phone_number], record[:patient_phone_number])
    end
  end

  def pass_thru_available?
    User.find_by_phone_number(@user_phone_number).present? &&
      PatientPhoneNumber.find_by_number(@patient_phone_number).present?
  end

  def save(call_id)
    record = { patient_phone_number: @patient_phone_number,
               user_phone_number: @user_phone_number }

    Rails.cache.write(KEY + call_id, record)
  end
end
