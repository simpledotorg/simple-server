module SmsHelper
  SMS_LOCALES = {
    punjab: :pa_Guru_IN,
    maharashtra: :mr_IN,
  }

  def sms_locale(state)
    SMS_LOCALES.fetch(state, :en)
  end

  def date_in_locale(date, locale)
    month_in_locale = I18n.t("months.#{date.month}", locale: locale)
    "#{date.day} #{month_in_locale}, #{date.year}"
  end
end
