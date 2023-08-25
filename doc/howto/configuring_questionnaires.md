# Configuring Questionnaires

The [Questionnaires ADR](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/020-questionnaires-aka-dynamic-forms.md) talks about the implementation from an end-user's perspective, and is a prerequisite for understanding this guide. This is a tutorial on configuring dynamic forms from server-side.

### 1. Creating a new questionnaire
When creating a new questionnaire, follow these steps:
1. Add a `questionnaire_type` to Questionnaire model, which is the source of truth for supported questionnaire types.
1. Create a layout based on the syntax specified for a DSL version in [swagger docs](https://api.simple.org/api-docs/index.html#tag/Questionnaire-Responses/paths/~1questionnaire_responses~1sync/get), the source of truth for syntax.
    1. When creating a layout, you can avoid adding an `id` for each view component, as that gets generate by a helper function inside Questionnaire model.
1. Inside a view component, `text` contains a translation reference, not the actual text.
    1. Server replaces data inside `text` with translations based on User's locale at the time of API request.

### 2. How Questionnaires sync API works?
Questionnaire sync API has different design & works in following way:
1. Since questionnaires are created and stored only on Server-side, there is only Sync-to-user and no Sync-from-user. On the other hand, questionnaire responses can be modified by a user and are synced both to & from a user.
1. Mobile requests questionnaires for the DSL Version it supports
1. Of all the questionnaires in the database, Server sends ONE questionnaire per type in following manner:
    1. The questionnaire should be active.
    1. The questionnaire's DSL version should match major version and be lesser than or equal to minor version supported by Mobile.
    1. If Mobile's DSL version is `2.4`, and server finds 3 active questionnaires for type screening reports `1.3`, `2.1` & `2.5`, Server will send a screening questionnaire of DSL version `2.1` in response.
    1. Server replaces `text` inside a questionnaire's layout with translations for a user's locale.
    1. Unlike other sync resources, where a region change triggers a `force_resync`, in case of questionnaires, a `locale` or `resync_token` change triggers a `force_resync`

### 3. Initializing questionnaire responses on server-side
A dynamic form response can be initialized either on Server or Mobile side. We initialized monthly-forms on Server-side for 3 reasons:
1. If any data must be pre-populated, Server has access to that data.
1. Mobile App update isn't required to accommodate any major change in requirements.
1. Monthly forms are exclusive per facility, and generating them on Server-side ensures 1 response per form per month per facility, meaning for `Jul-2023` a facility can only have 1 response of a Screening report type. 

Mobile displays a Questionnaire on home page based on [these 3 conditions](https://github.com/simpledotorg/simple-server/blob/master/doc/arch/020-questionnaires-aka-dynamic-forms.md#3.) mentioned in the ADR. Server follows below steps to generate responses for a questionnaire on a monthly basis:
1. Schedule a cron job to run every month at 6 AM
1. flipper flag check happens per questionnaire type before initializing responses. This flag helps run same code in multiple countries.
1. A QuestionnaireResponses service script is called to either initialize blank responses or pre-fill known data in the form.
1. At the beginning of every month, we want clinic staff to report data of the previous month. For that reason, Server initializes responses for the previous `month_date`.
    1. For instance, on 1st August 2023, `July-2023` response gets initialized for all facilities.
1. *Note: Server doesn't have any database or application layer constraints to ensure 1 response per form per month per facility. Rather, the service script performs a check for given month-year & facility before creating a response.*

### 4. Updating an existing questionnaire
Dynamic forms give us the freedom to add/remove fields without a Mobile App update. Follow these steps to update a form:

1. Unlike mobile database, where only ONE questionnaire can exist per type, server stores multiple questionnaires of same type for audit purposes.
1. For the questionnaire that needs updating, ready the new layout.
1. For a given DSL version, only ONE questionnaire can be active on server-side. This is enforced using a database constraint.
1. All questionnaires must be kept mutable for audit purposes.
1. To update a questionnaire, first mark existing `active` questionnaire as `inactive`.
1. After marking older questionnaire as `inactive`, create a new one and mark it as `active`.

### 5. Extending Questionnaire DSL to support more fields
The syntax of a questionnaire layout is defined by a DSL version. To add more input & display types to a questionnaire, the `dsl_version` must be incremented by following these steps:

1. DSL versions are defined in form of `X.Y`, where both X & Y are integers
1. When adding a new view component, if existing components' syntax aren't modified, that's called a backward-compatible extension.
1. For backward-compatible extensions, X stays same & Y is incremented by 1. For example, `1.1` gets updated to `1.2`.
1. Create a swagger specification for the new DSL version. Reuse components from older compatible DSL versions to reduce code churn & duplications. For example, checkout `Api::V4::Models::Questionnaires::DSLVersion1Dot2` swagger definition.
1. Add the new DSL version to `layout_schema`'s definitions in the Questionnaire model, the source of truth for supported DSL versions.
1. Add new swagger schema to definitions and update the `questionnaire`'s layout to include the new syntax.
1. A Mobile app update is required to propagate changes in DSL version. Older version won't be able to support newly added input/display types.
1. On Server-side, maintain active questionnaires of both versions `1.1` & `1.2` until all users have migrated to newly launched app.

### 6. Modifying (~~not Extending~~) Questionnaire DSL
When syntax/keys of older view components need to be changed to reflect newer requirements, a backward-incompatible extension must be made by following these steps:

1. X gets incremented by 1 and Y gets reset to 0. For example, `1.5` gets updated to `2.0`.
2. Update code, swagger schema & definitions as mentioned in above section.
3. When creating questionnaire for the new DSL, be mindful of not copy-pasting older syntax.
