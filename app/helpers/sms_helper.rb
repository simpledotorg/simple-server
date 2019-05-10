module SmsHelper
  def date_in_locale(date, locale)
    month_in_locale = I18n.t("months.#{date.month}", locale: locale)
    "#{date.day} #{month_in_locale}, #{date.year}"
  end
end
