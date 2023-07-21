module QuestionnaireResponsesHelper
  def latest_active_questionnaire_id(type)
    Questionnaire.active.where(questionnaire_type: type).order(dsl_version: :desc).first.try(:id)
  end

  def month_date_str
    @month_date.strftime("%Y-%m-%d")
  end

  def monthly_reports_base_content
    {
      "month_date" => month_date_str,
      "submitted" => false
    }
  end
end
