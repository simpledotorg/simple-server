# Configuring Questionnaires

# Workflow


#### 9. Creating a new type of questionnaire
#### 9. Adding/Removing fields from an existing questionnaire
- unlike mobile database, where ONLY ONE type of questionnaire exists, server will have multiple version of the same questionnaire.
- however, only 1 active questionnaire for a given DSL version

#### 10. Extending the questionnaire DSL
- moving from 1.1 to 1.2 or 2.0

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

1. Process to create new questionnaires or seed response data
- can be done via rails console or data migrations
- Prefer rails console because of ...

1. server's flipper flag is enabled, otherwise it won't initialize q_responses

1. document how to add data migrations
   
1. ?? Details/Meanings of a sample layout ??

