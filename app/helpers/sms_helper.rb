module SmsHelper
  def self.sms_locale(address)
    case
    when address.in_maharashtra? then
      :mh_IN
    when address.in_punjab? then
      :pa_Guru_IN
    else
      :en
    end
  end
end
