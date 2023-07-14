# Questionnaires (AKA Dynamic Forms)

## Status
Accepted

## Dictionary

- **Form:** A document to gather information in a structured manner.

## Context

Historically, a "form" at Simple has been static and designed as a first-class entity. For example, Blood Pressure has it's own API, database and a static UI on mobile. The challenge with static forms has been high time to production and inflexible UI. A new form demands a new API, table and UI development on mobile. Modifications to an existing form demands a version upgrade of the API and mobile app.

Static forms have served us well for infrequently changing forms like Blood Pressure and Blood Sugar. For forms that require frequent changes (like Drug-stock), we used WebView to accommodate the dynamic nature of this form. WebView isn't offline-first, like the rest of Simple app.

Questionnaires (aka Dynamic forms) is an effort at solving 2 challenges in an offline-first manner: reducing time to production & a flexibility to add/remove fields without need to update the Simple app. We also refer to them as Server-driven UI.

## Decision

We have designed Questionnaires by reusing underlying offline-first sync architecture of Simple. Definitions of new terminology introduced:
- **Questionnaire:** A sync resource containing form's layout and input fields, version and form-type.
- **Questionnaire Response:** A sync resource containing user's inputs for a form/questionnaire, and user/facility the input was recorded at.
- **Layout:** A custom DSL that helps Mobile rendering a form defined by server.

## Design (AKA Implementation Details)

Questionnaires are implemented by following below mentioned 10 steps:

#### 1. Mobile _syncs_ questionnaires from server to device
Mobile requests questionnaires from server using the questionnaire [this sync API](https://api.simple.org/api-docs/index.html#tag/Questionnaires). 

On Mobile database, the primary key is questionnaire_type, and not id. That is a key difference between Questionnaire and other sync resources.

| questionnaire_type | id     | layout   |
|--------------------|--------|----------|
| screening_reports  | uuid-1 | {form-1} |
| supplies_reports   | uuid-2 | {form-2} |

#### 2. Mobile _syncs_ questionnaire_responses from server to device
User inputs for a questionnaire are stored in form of a questionnaire response. Mobile requests them from server using [this sync API](https://api.simple.org/api-docs/index.html#tag/Questionnaire-Responses).

Other sync resources have explicit keys for recording input (Blood Pressures have "systolic"/"diastolic", Patients have "gender", etc.). Questionnaire response records all user inputs in a single field `content` of JSON data type.

| id      | questionnaire_id | facility_id | user_id | content        |
|---------|------------------|-------------|---------|----------------|
| uuid-11 | uuid-1           | Surat       | 123     | {"foo": "bar"} |
| uuid-22 | uuid-2           | Bangalore   | 456     | {"abc": "def"} |

#### 3. Displaying a list of forms
![questionnaire-responses-list](resources/questionnaire-responses-list.png)

When user clicks on a form type from home page, Mobile queries its table for responses of given questionnaire type. Mobile has some custom logic on ordering and style of the forms:
- Mobile orders forms in descending order of months by checking for `content["month_date"]` key.
- Mobile deduces submission status by checking for `content["submitted"]` key.

#### 4. User clicks on a form
![questionnaire-view](resources/questionnaire-view.png)

When user clicks on a form, Mobile renders UI of a questionnaire based on the layout. Current version of DSL has provisions for `integer/string input types`, `header/sub-header/paragraph/checklist display types`; and can be extended to more input/display types in future.

#### 5. User submits a form
When user submits a form, Mobile updates the `content`, `questionnaire_id`(to record the layout which was displayed to a user), `last_updated_by_user_id` & `facility_id` or a response.

A questionnaire's layout contains a `link_id` for input fields. Mobile uses them to display values in UI and record responses in the content key. 
A specimen content key's value looks like:
```json
{
  "submitted": true,
  "month_date": "08-2023",
  "monthly_screening_report.blood_pressure_checks_male": 10,
  "monthly_screening_report.comments": "All good"
}
```

#### 6. Handling concurrent updates
When server receives different questionnaire_responses for the same ID, it merges the 2 records in the following way:
1. Latest `device_updated_at` takes precedence for every field, except `content`.
2. A UNION of existing & new `content` is taken.
3. For conflicting keys within content, latest update takes precedence.
4. Consider this specimen workflow:
    1. User #1 fills keys A, B, C & D on 6 Dec
    2. User #2 fills keys C, D, E & F on 7 Dec
    3. Post union, DB will contain keys A, B, C, D, E & F
    4. C, D will be User #2’s data.

#### 7. User changes locale

Mobile stores 

#### 8. Releasing a new questionnaire layout

#### 9. Releasing a new questionnaire DSL version 



- Support versioning of forms –  when a form’s layout changes, older versions of the app should still be able to submit responses.
- Generating a questionnaire_response. Either client-side or server-side.
- Mobile uses (ask Sid) for rendering the layout dynamically
- Details/Meanings of a sample layout
- Handling locale changes
- Sequence diagram (flow-chart)

### FAQs
- how to modify a questionnaire
  - Since all the input fields are optional, creating a new questionnaire won’t need data migration & there won’t be any breaking changes ever.
  - adding a field
  - changing/deleting a field
    - nothing is mandatory, just optional
- Handling concurrent updates
  - https://docs.google.com/document/d/1oRL3RyE6BO4kMhDLxjmWSHMwtKVnknxBGuYu9yyVwn4/edit#heading=h.ki5h9mupnlv6
- Form version changes
  - copy from slack message with details

### Avoided Designs

- Not using FHIR questionnaires
- Using XForms as the DSL: XForms would have helped avoid re-inventing the wheel. However, it has a steep learning curve and documentation/ecosystem isn’t friendly.
  The [XForms specification](https://www.w3.org/TR/xforms20) is a lot to parse through. Ruby only has a single gem which lacks documentation ([sample XForm](https://bitbucket.org/instedd/ruby-xforms/src/master/spec/data/xform1.xml), [sample usage](https://bitbucket.org/instedd/ruby-xforms/src/master/spec/form_spec.rb))
  Rendering & parsing in the mobile app is complex (references: [ODK’s forum reply](https://forum.getodk.org/t/using-xform-in-the-mobile-app/16262/2)). We’ll have to use the [JavaRosa library](https://github.com/getodk/javarosa) for this.
- Storing forms in YAML: We want to support different forms per-country. In the future, we would like to support scoping, access control and modifying forms from the dashboard. Storing forms in the DB allows us to do all of these things.
