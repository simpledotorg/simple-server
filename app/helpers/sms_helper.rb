module SmsHelper
  def sms_locale(address)
    case
    when address.in_maharashtra? then
      :mh_IN
    when address.in_punjab? then
      :pa_Guru_IN
    else
      :en
    end
  end

  def date_in_locale(date, locale)
    month_in_locale = I18n.t("months.#{date.month}", locale: locale)
    "#{date.day} #{month_in_locale}, #{date.year}"
  end
end
