## Feature Toggles

Feature toggles are used the application to turn on, or off certain features of the backend.

There are two kinds of feature toggles used currently.
  - Boolean Toggles - Used to turn on or off a feature entirely.
    They are turned on by setting env variable `ENABLE_<capitalized_feature_name>` to true.
    Boolean feature toggles are turned off by default
  - Regex matchs: These are used to turn on or off a feature, by comparing strings to the provided regex
    They are turned on by setting env variable `ENABLE_REGEX_MATCH_FOR_<capitalized_feature_name>` to the allowed regex.

### Active Feature

#### PURGE_ENDPOINT_FOR_QA
Allows the database to be cleared up after running integration tests.
This feature should only be turned on for the QA env.

#### SMS_NOTIFICATION_FOR_OTP
Enables SMSes to be sent with OTPs for login
The feature can be turned off in environments where otp sms notifications need not be sent, eg: qa, development

#### ACCESSIBLE_SYNC_APIS
This is the only example of a regex match feature toggle.
Allows selectively enabling the sync apis. Sync apis which match the regex are turned on.

### Deprecated Feature

#### MULTIPLE_LOGIN
Feature used to enable multiple logins with a given OTP.
This feature was added to facilitate user testing by allowing multiple devices to login with the same OTP.

Reason for deprecation: An OTP can only be used on one device for login

#### SYNC_API_AUTHENTICATION
Enables authentication for sync APIs.
This feature was added to avoid breaking android build during development

Reason for deprecation: All sync api requests must be authenticated. 
