module Reports::FormsHelper
  def questionnaire_form_text(text_key)
    return if text_key.blank?

    I18n.t(text_key)
  rescue I18n::MissingTranslationData
    text_key.humanize
  end
end
