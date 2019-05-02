module SmsHelper
  def sms_locale(state)
    {
      punjab: :pa_Guru_IN,
      maharashtra: :mr_IN,
    }.fetch(state, :en)
  end

  def date_in_locale(date, locale)
    month_in_locale = I18n.t("months.#{date.month}", locale: locale)
    "#{date.day} #{month_in_locale}, #{date.year}"
  end
end
