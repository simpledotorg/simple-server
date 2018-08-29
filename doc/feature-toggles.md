# Feature Toggles

#### ENABLE_PURGE_ENDPOINT_FOR_QA
Type: Boolean
Default: false

Allows the database to be cleared up after running integration tests.
This feature should only be turned on for the QA env.

#### ENABLE_SMS_NOTIFICATION_FOR_OTP
Type: Boolean
Default: false

Enables SMSes to be sent with OTPs for login
The feature can be turned off in environments where otp sms notifications need not be sent, eg: qa, development

#### ENABLE_REGEX_MATCHING_SYNC_APIS
Type: Regex
Default: nil

Allows selectively enabling the sync apis. Sync apis which match the regex are turned on.

#### ENABLE_FIXED_OTP_ON_REQUEST_FOR_QA
Type: Boolean
Default: false

Does not reset otp for user when requested
This feature should only be turned on for the QA env.