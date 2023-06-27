# How to add Questionnaires (aka Dynamic Forms)

# Workflow

1. Adding a new questionnaire with layout
   
1. Seeding questionnaire_responses

1. Screening button will be displayed if three conditions are met:
  - If screening is enabled for facility/user/country, there should be a Questionnaire record of type monthly_screening_reports in the database
  - App will receive the enabled_monthly_screening_reports key in the facility API response. This should be true.
  - QuestionnaireResponses table has atleast 1 record of questionnaireType as `monthly_screening_reports`

1. Display screen
  - The app will use the month_date key to determine the month and localize it before displaying. The submitted key will be used to display if a month’s response has been submitted. 
  - This implies that these keys are “required/static” in a screening report questionnaire response.
  - The app must have display & translation logic for these static fields.

1. Submitting a form response

