# Feature Flags

Simple Server has several features flags that can be configured to enable/disable/partially enable different features in
different environments. Simple Server uses the [Flipper gem](https://github.com/jnunemaker/flipper) to implement its
feature flags.

The full list of feature flags and their purpose is given below. Some of these feature flags may be in use temporarily
to facility the launch of a new feature, and may reference the Simple team's internal documentation.

| Feature flag | Intended for production use? | Description |
| ---          | ---                          | ---         |
| auto_approve_users | No | When enabled, new app users are automatically approved to sync data. Users that reset their PIN are also automatically approved to sync data. Manual approval through the dashboard is not required.|
| dashboard_ui_refresh | Yes | Feature flag to launch [Dashboard UI Refresh](https://app.shortcut.com/simpledotorg/epic/4119/dashboard-ui-refresh?vc_group_by=day)|
| dhis2_export | Yes | When enabled, Simple Server will export data elements to the configured DHIS2 server |
| disable_region_cache_warmer | Yes | When enabled, Simple Server will not warm dashboard reports caches overnight. |
| disregard_messaging_window | No | When enabled, Simple Server will send reminder messages to patients as soon as they are scheduled, disregarding the configured time window for patient messaging (eg 10am-6pm). |
| drug_stocks | Yes | When enabled, the Simple Dashboard and app will allow configuration and submission of drug stock reports. |
| exotel_whitelist_api | Yes | When enabled, Simple Server will validate patient phone numbers with Exotel on a nightly basis to determine the phone number type (eg. mobile) as well as assess whether any of the phone numbers are part of Do-Not-Disturb lists. |
| experiment | Yes | When enabled, Simple Server will send experimental patient reminder messages based on any running patient reminder A/B experiments. |
| fixed_otp | No | When enabled, Simple Server will freeze all app user OTPs to `000000`. Intended for use in test environments only. |
| force_mark_patient_mobile_numbers | Yes | When enabled, Simple Server will automatically mark all patient phone numbers as "mobile" on a nightly basis. Disable this if patient phone number types are validated through other means (eg. Exotel API in India). |
| generate_encounter_id_endpoint | No | When enabled, the Simple API exposes a "generate_id" endpoint on the encounters sync resource. This endpoint would be used if encounter records were created client-side. |
| imo_messaging | Yes | When enabled, patient reminder messages will be attempted via Imo first, before falling back to SMS. |
| notifications | Yes | When enabled, Simple Server will send patient reminder messages. |
| organization_reports | Yes | When enabled, the Simple Dashboard will allow users to view a top-level report for the whole organization. |
| skip_api_validation | Yes | When enabled, Simple Server will not perform JSON validation of incoming API requests. This makes the API endpoints much more performant, but should only be enabled if all API clients are trusted (Simple app only). |
| sync_encounters | Yes | When enabled, encounters can be synced between app and server like any other standard sync resource. |
| weekly_telemed_report | Yes | When enabled, a weekly report on telemedicine activity in Simple will be sent via email to the configured recipients. |
| whatsapp_appointment_reminders | Yes | When enabled, patient reminder messages will be attempted via Whatsapp first, before falling back to SMS. |
